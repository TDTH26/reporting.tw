"""Informant API: anonymous report submission, follow-up by secret token, evidence requests."""

import hashlib
import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .. import interview
from ..abuse.attestation import verifier
from ..abuse.limits import assess
from ..config import get_settings
from ..db.models import (
    Case,
    CaseEvent,
    Evidence,
    EvidenceRequest,
    InformantCase,
    InformantToken,
    Observation,
    Template,
    Zone,
)
from ..db.session import get_session
from ..domain.enums import BASE_CONFIDENCE, DEFENSE_OUTCOME, CaseAction, CaseState, SourceType
from ..domain.state import informant_status
from ..fusion.engine import fuse
from ..live.bus import publish_case
from ..routing.router import apply_incident_update, event
from ..security.hashing import client_ip, keyed_hash, network_of
from .informant_auth import current_informant, mint_token, secret_matches, sign_upload
from .report_schemas import (
    EvidenceRequestOut,
    EvidenceResponseIn,
    InformantCaseOut,
    MediaDeclaration,
    PushRegistrationIn,
    ReportIn,
    ReportOut,
    TimelineEntry,
    UploadTicket,
)

router = APIRouter(prefix="/v1", tags=["informant"])

MAX_CLOCK_SKEW = timedelta(minutes=10)
MAX_REPORT_AGE = timedelta(hours=24)


def request_hash(r: ReportIn) -> str:
    """Binds a Play Integrity token to this exact packet. Clients compute the same string."""
    # Integer arithmetic: float timestamps can be off by one millisecond.
    ms = (r.observed_at - datetime(1970, 1, 1, tzinfo=UTC)) // timedelta(milliseconds=1)
    hashes = ",".join(sorted(m.sha256 for m in r.media))
    canon = f"uavr-report-v1|{r.client_report_id}|{ms}|{r.observer.lat:.6f}|{r.observer.lon:.6f}|{hashes}"
    return hashlib.sha256(canon.encode()).hexdigest()


def _tickets(evs: list[tuple[str, Evidence]]) -> list[UploadTicket]:
    url = get_settings().tus_public_url
    return [
        UploadTicket(slot=slot, evidence_id=e.id, upload_url=url, upload_token=sign_upload(e.id)) for slot, e in evs
    ]


def _evidence(obs_id: uuid.UUID, m: MediaDeclaration, attestation: str | None, req_id=None) -> Evidence:
    return Evidence(
        id=uuid.uuid4(),
        observation_id=obs_id,
        evidence_request_id=req_id,
        kind=m.kind.value,
        mime_type=m.mime_type,
        sha256_declared=m.sha256,
        size_bytes=m.size_bytes,
        captured_at=m.captured_at,
        attestation=attestation,
        status="pending",
    )


def _remote_id_summary(r: ReportIn) -> dict:
    msgs = sorted(r.remote_id, key=lambda m: m.received_at)
    serial = next((m.uas_id for m in reversed(msgs) if m.uas_id), None)
    loc = next((m for m in reversed(msgs) if m.lat is not None and m.lon is not None), None)
    op = next((m for m in reversed(msgs) if m.operator_lat is not None and m.operator_lon is not None), None)
    return {"serial": serial, "location": loc, "operator": op}


@router.post("/reports", response_model=ReportOut, status_code=201)
async def submit_report(r: ReportIn, request: Request, session: AsyncSession = Depends(get_session)) -> ReportOut:
    now = datetime.now(UTC)
    if r.observed_at > now + MAX_CLOCK_SKEW or r.observed_at < now - MAX_REPORT_AGE:
        raise HTTPException(422, "observed_at is outside the accepted window")

    # Idempotent retry from the offline queue.
    existing = (
        await session.execute(select(Observation).where(Observation.client_report_id == r.client_report_id))
    ).scalar_one_or_none()
    if existing is not None:
        tok = await session.get(InformantToken, existing.informant_token_id)
        if not (r.token_secret and tok and secret_matches(tok, r.token_secret)):
            raise HTTPException(status.HTTP_409_CONFLICT, "report already received")
        case = (
            (await session.execute(select(Case).join(InformantCase).where(InformantCase.token_id == tok.id).limit(1)))
            .unique()
            .scalar_one()
        )
        pending = [(str(i), e) for i, e in enumerate(existing.evidence) if e.status == "pending"]
        slots = {m.sha256: m.slot for m in r.media}
        pending = [(slots.get(e.sha256_declared, s), e) for s, e in pending]
        return ReportOut(
            case_number=case.case_number,
            token=f"{tok.id}.{r.token_secret}",
            status=informant_status(CaseState(case.state)),
            fidelity=existing.fidelity or "low",
            uploads=_tickets(pending),
            suggest_android_app=r.platform == "web",
        )

    try:
        facts = interview.evaluate(r.interview, r.interview_version)
    except interview.InterviewError as e:
        raise HTTPException(422, str(e)) from e
    domain = r.craft_domain or (facts.domain if r.interview else "aerial")

    is_web = r.platform == "web"
    source = SourceType.informant_web if is_web else SourceType.informant_android
    device_hash = keyed_hash("device", r.device_id)
    net = network_of(client_ip(request))
    network_hash = keyed_hash("network", net) if net else None

    if is_web:
        attestation = "skipped"
    else:
        package = "tw.reporting.app"
        attestation = (await verifier().verify(r.attestation_token, request_hash(r), package)).result

    abuse = await assess(
        session,
        device_hash=device_hash,
        network_hash=network_hash,
        attestation=attestation,
        is_web=is_web,
        evidence_hashes=[m.sha256 for m in r.media],
        t=now,
    )
    if abuse.reject:
        await session.commit()  # keep the counter increment
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "too many reports from this device")

    tid, token, secret_hash = mint_token(r.token_secret)
    tok = InformantToken(
        id=tid,
        secret_hash=secret_hash,
        language=r.language,
        push_token=r.push_token,
        push_platform=r.platform if r.push_token else None,
    )
    session.add(tok)
    await session.flush()

    rid = _remote_id_summary(r)
    confidence = BASE_CONFIDENCE[source]
    if rid["serial"] or rid["location"]:
        confidence = max(confidence, 0.7)  # machine-generated broadcast data
    bearing_ok = r.bearing_deg is not None and not is_web
    fidelity = "high" if bearing_ok else "low"
    obs = Observation(
        id=uuid.uuid4(),
        client_report_id=r.client_report_id,
        source_type=source.value,
        source_id=None,
        observed_at=r.observed_at,
        observer_lat=r.observer.lat,
        observer_lon=r.observer.lon,
        observer_accuracy_m=r.observer.accuracy_m,
        bearing_deg=r.bearing_deg,
        bearing_accuracy_deg=r.bearing_accuracy_deg or (25.0 if is_web else 10.0),
        elevation_deg=r.elevation_deg,
        altitude_m=r.est_altitude_m,
        altitude_source="informant_estimate" if r.est_altitude_m is not None else None,
        confidence=confidence,
        spam_score=abuse.spam_score,
        fidelity=fidelity,
        attestation=attestation,
        device_hash=device_hash,
        network_hash=network_hash,
        description=r.description,
        description_lang=r.language,
        craft_domain=domain,
        craft_type=facts.craft_type,
        interview={"version": interview.VERSION, "answers": r.interview} if r.interview else None,
        raw_payload={
            **r.model_dump(mode="json", exclude={"attestation_token", "push_token", "device_id", "token_secret"}),
            "abuse": {"score": abuse.spam_score, "reasons": abuse.reasons},
            "est_distance_m": r.est_distance_m
            or interview.DISTANCE_M.get((r.interview or {}).get("distance_offshore", "")),
        },
        schema_version="informant-report/1",
        informant_token_id=tid,
    )
    if rid["serial"]:
        obs.remote_id_serial = rid["serial"]
    if loc := rid["location"]:
        obs.drone_lat, obs.drone_lon = loc.lat, loc.lon
        obs.altitude_m = loc.height_m if loc.height_m is not None else loc.alt_geo_m
        obs.altitude_source = "remote_id"
    if op := rid["operator"]:
        obs.operator_lat, obs.operator_lon = op.operator_lat, op.operator_lon
    if r.remote_id:
        obs.remote_id = {
            "serial": rid["serial"],
            "messages": len(r.remote_id),
            "transports": sorted({m.transport for m in r.remote_id}),
            "operator_id": next((m.operator_id for m in r.remote_id if m.operator_id), None),
        }
    session.add(obs)
    evs = [(m.slot, _evidence(obs.id, m, attestation)) for m in r.media]
    session.add_all(e for _, e in evs)
    await session.flush()

    incident, created = await fuse(session, obs)
    case = await apply_incident_update(session, incident, created)
    session.add(InformantCase(token_id=tid, case_id=case.id))
    await session.commit()

    return ReportOut(
        case_number=case.case_number,
        token=token,
        status=informant_status(CaseState(case.state)),
        fidelity=fidelity,
        uploads=_tickets(evs),
        suggest_android_app=is_web,
    )


async def _template_texts(session: AsyncSession) -> dict[str, Template]:
    return {t.code: t for t in (await session.execute(select(Template))).scalars()}


def _text(t: Template | None, lang: str) -> str | None:
    if t is None:
        return None
    return t.texts.get(lang) or t.texts.get("en") or next(iter(t.texts.values()), None)


INFORMANT_VISIBLE = {
    CaseAction.created.value: "received",
    CaseAction.acknowledged.value: "in_review",
    CaseAction.investigating.value: "in_progress",
    CaseAction.resolved.value: "completed",
}


async def _resolve_case(session: AsyncSession, case: Case) -> Case:
    """Follow merges so a informant always sees the surviving case."""
    seen = set()
    while case.merged_into_id and case.id not in seen:
        seen.add(case.id)
        case = await session.get(Case, case.merged_into_id)
    return case


@router.get("/informant/cases", response_model=list[InformantCaseOut])
async def my_cases(
    lang: str | None = None,
    tok: InformantToken = Depends(current_informant),
    session: AsyncSession = Depends(get_session),
) -> list[InformantCaseOut]:
    language = lang or tok.language
    templates = await _template_texts(session)
    cases = (
        (await session.execute(select(Case).join(InformantCase).where(InformantCase.token_id == tok.id)))
        .unique()
        .scalars()
        .all()
    )
    out = []
    for c0 in cases:
        c = await _resolve_case(session, c0)
        events = (
            await session.execute(
                select(CaseEvent)
                .where(CaseEvent.case_id.in_({c.id, c0.id}), CaseEvent.action.in_(INFORMANT_VISIBLE))
                .order_by(CaseEvent.at)
            )
        ).scalars()
        timeline: list[TimelineEntry] = []
        for e in events:
            st = INFORMANT_VISIBLE[e.action]
            if not timeline or timeline[-1].status != st:
                timeline.append(TimelineEntry(status=st, at=e.at))
        outcome_code = None
        if c.state in (CaseState.resolved.value, CaseState.closed.value):
            outcome_code = DEFENSE_OUTCOME if c.classification >= 2 else c.outcome_code
        reqs = (
            await session.execute(
                select(EvidenceRequest)
                .where(EvidenceRequest.token_id == tok.id, EvidenceRequest.status != "cancelled")
                .where(EvidenceRequest.case_id.in_({c.id, c0.id}))
                .order_by(EvidenceRequest.created_at)
            )
        ).scalars()
        out.append(
            InformantCaseOut(
                case_number=c0.case_number,
                status=informant_status(CaseState(c.state)),
                outcome_code=outcome_code,
                outcome_text=_text(templates.get(outcome_code), language) if outcome_code else None,
                updated_at=c.updated_at,
                timeline=timeline,
                evidence_requests=[
                    EvidenceRequestOut(
                        id=q.id,
                        template_code=q.template_code,
                        text=_text(templates.get(q.template_code), language) or q.template_code,
                        requested_kinds=templates[q.template_code].requested_kinds
                        if q.template_code in templates
                        else [],
                        status=q.status,
                        created_at=q.created_at,
                    )
                    for q in reqs
                ],
            )
        )
    await session.commit()
    return out


@router.post("/informant/evidence-requests/{request_id}/responses", response_model=list[UploadTicket])
async def answer_evidence_request(
    request_id: uuid.UUID,
    body: EvidenceResponseIn,
    tok: InformantToken = Depends(current_informant),
    session: AsyncSession = Depends(get_session),
) -> list[UploadTicket]:
    req = await session.get(EvidenceRequest, request_id)
    if req is None or req.token_id != tok.id:
        raise HTTPException(404, "request not found")
    if req.status != "open":
        raise HTTPException(409, "request is no longer open")
    obs = (
        await session.execute(select(Observation).where(Observation.informant_token_id == tok.id).limit(1))
    ).scalar_one()
    evs = [(m.slot, _evidence(obs.id, m, obs.attestation, req.id)) for m in body.media]
    session.add_all(e for _, e in evs)
    req.status = "answered"
    req.answered_at = datetime.now(UTC)
    case = await session.get(Case, req.case_id)
    session.add(
        event(
            case, CaseAction.evidence_received, actor="informant", data={"request_id": str(req.id), "files": len(evs)}
        )
    )
    await session.flush()
    await publish_case(session, "case.evidence", case)
    await session.commit()
    return _tickets(evs)


@router.put("/informant/push", status_code=204)
async def register_push(
    body: PushRegistrationIn,
    tok: InformantToken = Depends(current_informant),
    session: AsyncSession = Depends(get_session),
) -> None:
    tok.push_token = body.push_token
    tok.push_platform = body.platform
    if body.language:
        tok.language = body.language
    await session.commit()


@router.get("/public/zones")
async def published_zones(session: AsyncSession = Depends(get_session)) -> dict:
    """Published CAA zones only. Sensitive-site polygons never leave the server."""
    zones = (await session.execute(select(Zone).where(Zone.published, Zone.active, Zone.classification == 0))).scalars()
    return {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "id": z.code,
                "properties": {"code": z.code, "name": z.name, "name_zh": z.name_zh, "zone_type": z.zone_type},
                "geometry": z.geometry,
            }
            for z in zones
        ],
    }


@router.get("/public/interview")
async def interview_questions(lang: str = "zh-TW") -> dict:
    """The structured interview, pre-translated. Clients render it as served."""
    return interview.questionnaire(lang)


@router.get("/public/config")
async def public_config() -> dict:
    s = get_settings()
    return {
        "tus_url": s.tus_public_url,
        "languages": ["zh-TW", "en", "vi", "id", "th", "fil", "de", "fr"],
        "min_android_version": "1.0.0",
        "request_hash_format": "uavr-report-v1",
    }
