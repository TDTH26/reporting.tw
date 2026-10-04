"""Agency API (console + field app). Access is checked per request with ABAC and audited."""

import uuid
from datetime import UTC, datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy import false, func, or_, select, true
from sqlalchemy.ext.asyncio import AsyncSession

from .. import recommend
from ..cases import service
from ..db.models import (
    Agency,
    AircraftTrack,
    AppUser,
    Case,
    CaseEvent,
    CaseFieldAssignment,
    CaseRecommendation,
    CctvCamera,
    Desk,
    Evidence,
    EvidenceRequest,
    Incident,
    LiveEvent,
    Observation,
    Permit,
    RegistryEntry,
    Template,
    VesselTrack,
    VideoFeed,
    VideoTrack,
    Zone,
)
from ..db.session import get_session
from ..domain.enums import CaseAction, SourceType
from ..domain.geo import distance_m
from ..domain.state import OPEN_STATES
from ..fusion.engine import json_has, recompute
from ..geoutil import bbox_deg, bearing_line, latlon, line_geojson
from ..routing.router import apply_incident_update, case_for_incident, event
from ..security import crypto
from ..security.abac import Access, can_act, case_access, require_act, require_case_access, sees_sensitive_fields
from ..security.audit import audit
from ..security.auth import current_staff, require
from ..security.principal import (
    ROLE_ANALYST,
    ROLE_DISPATCHER,
    ROLE_FIELD,
    ROLE_NATIONAL,
    ROLE_SUPERVISOR,
    Principal,
)
from ..storage import files
from ..translate.client import translate
from ..views import case_summary, redacted_summary
from .agency_schemas import (
    AssignIn,
    DutyIn,
    EvidenceRequestIn,
    FieldAssignIn,
    FieldObservationIn,
    MergeIn,
    NoteIn,
    PositionIn,
    ResolveIn,
    SeverityIn,
    TransferIn,
)
from .reports import _evidence, _tickets

router = APIRouter(prefix="/v1/agency", tags=["agency"])
field_router = APIRouter(prefix="/v1/field", tags=["field"])

DISPATCH = (ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_NATIONAL)
READERS = (ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_NATIONAL, ROLE_ANALYST)


async def _assignees(session: AsyncSession, case_id: uuid.UUID) -> set[uuid.UUID]:
    return set(
        (
            await session.execute(
                select(CaseFieldAssignment.user_id).where(
                    CaseFieldAssignment.case_id == case_id, CaseFieldAssignment.active
                )
            )
        ).scalars()
    )


async def _load(session: AsyncSession, case_id: uuid.UUID) -> Case:
    c = (await session.execute(select(Case).where(Case.id == case_id))).unique().scalar_one_or_none()
    if c is None:
        raise HTTPException(404, "case not found")
    return c


def _visible_filter(p: Principal):
    """SQL pre-filter matching abac.case_access (the per-row check still runs afterwards)."""
    if p.has(ROLE_NATIONAL):
        return true()
    conds = []
    if p.agency_id is not None and p.has(*READERS):
        conds += [Case.agency_id == p.agency_id, json_has(Case.read_agency_ids, p.agency_id)]
    if p.desk_id is not None:
        conds.append(json_has(Case.redacted_desk_ids, p.desk_id))
    return or_(*conds) if conds else false()


# ------------------------------------------------------------------ me / roster


@router.get("/me")
async def me(p: Principal = Depends(current_staff), session: AsyncSession = Depends(get_session)) -> dict:
    u = await session.get(AppUser, p.user_id)
    desk = await session.get(Desk, p.desk_id) if p.desk_id else None
    agency = await session.get(Agency, p.agency_id) if p.agency_id else None
    return {
        "id": str(p.user_id),
        "username": p.username,
        "display_name": p.display_name,
        "roles": sorted(p.roles),
        "clearance": p.clearance,
        "field_unit": p.field_unit,
        "on_duty": u.on_duty if u else False,
        "desk": {"id": desk.id, "code": desk.code, "name": desk.name, "name_zh": desk.name_zh} if desk else None,
        "agency": {
            "id": agency.id,
            "code": agency.code,
            "name": agency.name,
            "name_zh": agency.name_zh,
            "kind": agency.kind,
        }
        if agency
        else None,
    }


@router.put("/me/duty")
async def set_duty(body: DutyIn, p: Principal = Depends(current_staff), session: AsyncSession = Depends(get_session)):
    u = await session.get(AppUser, p.user_id)
    u.on_duty = body.on_duty
    u.on_duty_since = datetime.now(UTC) if body.on_duty else None
    await audit(session, p, "roster.duty", "desk", str(p.desk_id), on_duty=body.on_duty)
    await session.commit()
    return {"on_duty": u.on_duty}


@router.get("/desks")
async def desks(p: Principal = Depends(current_staff), session: AsyncSession = Depends(get_session)) -> list[dict]:
    rows = (await session.execute(select(Desk).order_by(Desk.agency_id, Desk.id))).unique().scalars()
    return [
        {
            "id": d.id,
            "code": d.code,
            "name": d.name,
            "name_zh": d.name_zh,
            "agency_id": d.agency_id,
            "agency_code": d.agency.code,
            "clearance": d.clearance,
            "is_catch_all": d.is_catch_all,
            "always_staffed": d.always_staffed,
        }
        for d in rows
    ]


@router.get("/roster")
async def roster(
    desk_id: int | None = None,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
) -> list[dict]:
    q = select(AppUser).where(AppUser.agency_id == p.agency_id) if not p.has(ROLE_NATIONAL) else select(AppUser)
    if desk_id:
        q = q.where(AppUser.desk_id == desk_id)
    return [
        {
            "id": str(u.id),
            "username": u.username,
            "display_name": u.display_name,
            "desk_id": u.desk_id,
            "roles": u.roles,
            "on_duty": u.on_duty,
            "field_unit": u.field_unit,
            "last_position": latlon(u.last_lat, u.last_lon),
            "last_position_at": u.last_position_at.isoformat() if u.last_position_at else None,
        }
        for u in (await session.execute(q.order_by(AppUser.username))).scalars()
    ]


@router.get("/templates")
async def templates(p: Principal = Depends(current_staff), session: AsyncSession = Depends(get_session)) -> list[dict]:
    rows = (
        await session.execute(select(Template).where(Template.active).order_by(Template.kind, Template.sort))
    ).scalars()
    return [
        {
            "code": t.code,
            "kind": t.kind,
            "texts": t.texts,
            "requested_kinds": t.requested_kinds,
            "counts_as_false_report": t.counts_as_false_report,
        }
        for t in rows
    ]


# ------------------------------------------------------------------ queue and detail


@router.get("/queue")
async def queue(
    scope: str = Query("desk", pattern="^(desk|agency|all)$"),
    states: str = "new,acknowledged,investigating",
    limit: int = Query(200, le=1000),
    p: Principal = Depends(require(*READERS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    wanted = [s for s in states.split(",") if s]
    q = select(Case).where(Case.state.in_(wanted), _visible_filter(p))
    if scope == "desk" and p.desk_id:
        q = q.where(or_(Case.desk_id == p.desk_id, json_has(Case.redacted_desk_ids, p.desk_id)))
    elif scope == "agency" and p.agency_id:
        q = q.where(or_(Case.agency_id == p.agency_id, json_has(Case.read_agency_ids, p.agency_id)))
    q = q.order_by(
        Case.severity.desc(), Case.ack_deadline.is_(None), Case.ack_deadline.asc(), Case.created_at.desc()
    ).limit(limit)
    cases = (await session.execute(q)).unique().scalars().all()
    out = []
    for c in cases:
        a = case_access(p, c)
        if a == Access.none:
            continue
        item = case_summary(c) if a == Access.full else redacted_summary(c)
        item["can_act"] = can_act(p, c)
        out.append(item)
    # Clients resync from this seq after a WebSocket reconnect.
    seq = (await session.execute(select(func.coalesce(func.max(LiveEvent.seq), 0)))).scalar_one()
    return {"seq": seq, "cases": out}


async def _translated(session: AsyncSession, o: Observation, lang: str) -> str | None:
    if not o.description or o.description_lang == lang:
        return None
    cached = (o.description_translations or {}).get(lang)
    if cached:
        return cached
    t = await translate(o.description, o.description_lang, lang)
    if t:
        o.description_translations = {**(o.description_translations or {}), lang: t}
    return t


def _obs_view(o: Observation, sensitive: bool) -> dict:
    is_sensor = o.source_type in (
        SourceType.rf_sensor.value,
        SourceType.radar.value,
        SourceType.remote_id.value,
        SourceType.mda_sensor.value,
    )
    show_observer = sensitive or not is_sensor
    return {
        "id": str(o.id),
        "source_type": o.source_type,
        "source_id": o.source_id if (sensitive or not is_sensor) else None,
        "observed_at": o.observed_at.isoformat(),
        "received_at": o.received_at.isoformat() if o.received_at else None,
        "observer_position": latlon(o.observer_lat, o.observer_lon) if show_observer else None,
        "observer_accuracy_m": o.observer_accuracy_m,
        "drone_position": latlon(o.drone_lat, o.drone_lon),
        "bearing_deg": o.bearing_deg,
        "bearing_accuracy_deg": o.bearing_accuracy_deg,
        "elevation_deg": o.elevation_deg,
        "bearing_line": bearing_line(o.observer_lat, o.observer_lon, o.bearing_deg) if show_observer else None,
        "altitude_m": o.altitude_m,
        "altitude_source": o.altitude_source,
        "track": line_geojson(o.track),
        "remote_id_serial": o.remote_id_serial,
        "remote_id": o.remote_id,
        "operator_position": latlon(o.operator_lat, o.operator_lon),
        "confidence": round(o.confidence, 3),
        "spam_score": round(o.spam_score, 3),
        "fidelity": o.fidelity,
        "attestation": o.attestation,
        "description": o.description,
        "description_lang": o.description_lang,
        "craft_domain": o.craft_domain,
        "craft_type": o.craft_type,
        "interview": o.interview,
        "ai_assessment": o.ai_assessment,
        "evidence": [
            {
                "id": str(e.id),
                "kind": e.kind,
                "mime_type": e.mime_type,
                "status": e.status,
                "sha256": e.sha256_declared,
                "sha256_verified": e.sha256_verified,
                "size_bytes": e.size_bytes,
                "captured_at": e.captured_at.isoformat(),
                "uploaded_at": e.uploaded_at.isoformat() if e.uploaded_at else None,
                "evidence_request_id": str(e.evidence_request_id) if e.evidence_request_id else None,
            }
            for e in o.evidence
        ],
    }


async def case_detail(session: AsyncSession, c: Case, p: Principal, access: Access, request: Request | None) -> dict:
    if access == Access.redacted:
        await audit(session, p, "case.view_redacted", "case", str(c.id), request)
        return {**redacted_summary(c), "can_act": False}
    inc: Incident = c.incident
    sensitive = sees_sensitive_fields(p)
    zones = (
        (await session.execute(select(Zone).where(Zone.id.in_(inc.matched_zone_ids or [])))).scalars().all()
        if inc.matched_zone_ids
        else []
    )
    permit = await session.get(Permit, inc.permit_id) if inc.permit_id else None
    reg = await session.get(RegistryEntry, inc.registry_serial) if inc.registry_serial else None
    obs = (
        (
            await session.execute(
                select(Observation)
                .where(Observation.incident_id == inc.id)
                .order_by(Observation.observed_at)
                .limit(500)
            )
        )
        .scalars()
        .all()
    )
    obs_out = []
    for o in obs:
        v = _obs_view(o, sensitive)
        v["description_translated"] = await _translated(session, o, p.language)
        obs_out.append(v)
    events = (
        (await session.execute(select(CaseEvent).where(CaseEvent.case_id == c.id).order_by(CaseEvent.at, CaseEvent.id)))
        .scalars()
        .all()
    )
    assignees = (
        (
            await session.execute(
                select(AppUser)
                .join(CaseFieldAssignment, CaseFieldAssignment.user_id == AppUser.id)
                .where(CaseFieldAssignment.case_id == c.id, CaseFieldAssignment.active)
            )
        )
        .scalars()
        .all()
    )
    reqs = (
        await session.execute(
            select(EvidenceRequest.template_code, EvidenceRequest.status, func.count())
            .where(EvidenceRequest.case_id == c.id)
            .group_by(EvidenceRequest.template_code, EvidenceRequest.status)
        )
    ).all()
    detail = {
        **case_summary(c),
        "can_act": can_act(p, c),
        "outcome_code": c.outcome_code,
        "outcome_note": c.outcome_note,
        "route_chain": c.route_chain,
        "route_index": c.route_index,
        "read_agency_ids": c.read_agency_ids,
        "redacted_desk_ids": c.redacted_desk_ids,
        "merged_into_id": str(c.merged_into_id) if c.merged_into_id else None,
        "incident": {
            "id": str(inc.id),
            "zones": [
                {
                    "id": z.id,
                    "code": z.code,
                    "name": z.name,
                    "name_zh": z.name_zh,
                    "zone_type": z.zone_type,
                    "classification": z.classification,
                }
                for z in zones
                if z.classification <= p.clearance
            ],
            "operator_position": latlon(inc.operator_lat, inc.operator_lon),
            "adsb_nearby": inc.adsb_nearby,
            "weather": inc.weather,
            "permit": {
                "permit_no": permit.permit_no,
                "operator_name": permit.operator_name,
                "valid_from": permit.valid_from.isoformat(),
                "valid_to": permit.valid_to.isoformat(),
                "max_alt_m": permit.max_alt_m,
            }
            if permit
            else None,
            "registry_match": {
                "serial": reg.serial,
                "model": reg.model,
                "manufacturer": reg.manufacturer,
                "status": reg.status,
            }
            if reg
            else None,
        },
        "observations": obs_out,
        "events": [
            {
                "id": e.id,
                "at": e.at.isoformat(),
                "actor_type": e.actor_type,
                "actor_id": e.actor_id,
                "action": e.action,
                "from_state": e.from_state,
                "to_state": e.to_state,
                "from_desk_id": e.from_desk_id,
                "to_desk_id": e.to_desk_id,
                "reason": e.reason,
                "data": e.data,
            }
            for e in events
        ],
        "field_officers": [
            {
                "id": str(u.id),
                "username": u.username,
                "display_name": u.display_name,
                "last_position": latlon(u.last_lat, u.last_lon),
                "last_position_at": u.last_position_at.isoformat() if u.last_position_at else None,
            }
            for u in assignees
        ],
        "evidence_requests": [{"template_code": r[0], "status": r[1], "count": r[2]} for r in reqs],
        "defense_notes": crypto.decrypt(c.defense_notes_enc, c.id.bytes)
        if c.defense_notes_enc and p.clearance >= 2
        else None,
    }
    await audit(session, p, "case.view", "case", str(c.id), request)
    return detail


@router.get("/cases/{case_id}")
async def get_case(
    case_id: uuid.UUID,
    request: Request,
    p: Principal = Depends(current_staff),
    session: AsyncSession = Depends(get_session),
) -> dict:
    c = await _load(session, case_id)
    a = require_case_access(p, c, Access.redacted, await _assignees(session, c.id))
    d = await case_detail(session, c, p, a, request)
    await session.commit()
    return d


@router.get("/cases/by-number/{number}")
async def get_case_by_number(
    number: str, request: Request, p: Principal = Depends(current_staff), session: AsyncSession = Depends(get_session)
) -> dict:
    c = (await session.execute(select(Case).where(Case.case_number == number))).unique().scalar_one_or_none()
    if c is None:
        raise HTTPException(404, "case not found")
    return await get_case(c.id, request, p, session)


# ------------------------------------------------------------------ actions


async def _act(session: AsyncSession, case_id: uuid.UUID, p: Principal) -> Case:
    c = await service.lock_case(session, case_id)
    require_act(p, c)
    return c


async def _done(session: AsyncSession, c: Case) -> dict:
    await session.commit()
    c = await _load(session, c.id)
    return case_summary(c)


@router.post("/cases/{case_id}/acknowledge")
async def acknowledge(
    case_id: uuid.UUID, p: Principal = Depends(require(*DISPATCH)), session: AsyncSession = Depends(get_session)
):
    c = await _act(session, case_id, p)
    await service.acknowledge(session, c, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/investigate")
async def investigate(
    case_id: uuid.UUID, p: Principal = Depends(require(*DISPATCH)), session: AsyncSession = Depends(get_session)
):
    c = await _act(session, case_id, p)
    await service.start_investigation(session, c, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/transfer")
async def transfer(
    case_id: uuid.UUID,
    body: TransferIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    await service.transfer(session, c, body.desk_id, body.reason, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/merge")
async def merge(
    case_id: uuid.UUID,
    body: MergeIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    first, second = sorted([case_id, body.other_case_id])  # lock order avoids deadlocks
    a = await service.lock_case(session, first)
    b = await service.lock_case(session, second)
    survivor, absorbed = (a, b) if a.id == case_id else (b, a)
    require_act(p, survivor)
    if case_access(p, absorbed) != Access.full:
        raise HTTPException(403, "no full access to the case being merged")
    await service.merge(session, survivor, absorbed, body.reason, p)
    return await _done(session, survivor)


@router.post("/cases/{case_id}/severity")
async def severity(
    case_id: uuid.UUID,
    body: SeverityIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    await service.set_severity(session, c, body.severity, body.reason, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/resolve")
async def resolve(
    case_id: uuid.UUID,
    body: ResolveIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    await service.resolve(session, c, body.outcome_code, body.note, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/close")
async def close(
    case_id: uuid.UUID,
    p: Principal = Depends(require(ROLE_SUPERVISOR, ROLE_DISPATCHER)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    await service.close(session, c, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/evidence-requests")
async def evidence_request(
    case_id: uuid.UUID,
    body: EvidenceRequestIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    n = await service.request_evidence(session, c, body.template_code, p)
    await session.commit()
    return {"informants": n}


@router.post("/cases/{case_id}/notes")
async def note(
    case_id: uuid.UUID,
    body: NoteIn,
    p: Principal = Depends(require(*DISPATCH, ROLE_FIELD)),
    session: AsyncSession = Depends(get_session),
):
    c = await service.lock_case(session, case_id)
    require_case_access(p, c, Access.full, await _assignees(session, c.id))
    await service.add_note(session, c, body.text, body.defense, p)
    return await _done(session, c)


class RecommendationDecisionIn(BaseModel):
    decision: Literal["accept", "reject", "modify"]
    text: str | None = Field(None, max_length=2000)  # the operator's version (modify)
    note: str | None = Field(None, max_length=2000)


@router.get("/cases/{case_id}/recommendations")
async def recommendations(
    case_id: uuid.UUID,
    p: Principal = Depends(require(*READERS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Suggested responses (decision support only); refreshed from the case's current picture."""
    c = await _load(session, case_id)
    require_case_access(p, c, Access.full, await _assignees(session, c.id))
    rows = await recommend.refresh(session, c)
    out = {"recommendations": [recommend.as_dict(r) for r in rows], "can_act": can_act(p, c)}
    await session.commit()
    return out


@router.post("/cases/{case_id}/recommendations/{rec_id}")
async def decide_recommendation(
    case_id: uuid.UUID,
    rec_id: int,
    body: RecommendationDecisionIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    c = await _act(session, case_id, p)
    r = await session.get(CaseRecommendation, rec_id)
    if r is None or r.case_id != c.id:
        raise HTTPException(404, "recommendation not found")
    if body.decision == "modify" and not (body.text or "").strip():
        raise HTTPException(422, "a modified recommendation needs its new text")
    r.status = {"accept": "accepted", "reject": "rejected", "modify": "modified"}[body.decision]
    r.final_text = body.text.strip() if body.decision == "modify" else None
    r.note, r.decided_by, r.decided_at = body.note, p.username, recommend.now()
    session.add(
        event(
            c,
            CaseAction.recommendation,
            actor="user",
            actor_id=str(p.user_id),
            reason=r.final_text or r.text,
            data={"code": r.code, "decision": r.status, "note": body.note},
        )
    )
    # The one real action: accepting a field-unit suggestion assigns that officer to the case.
    if r.kind == "field" and r.status in ("accepted", "modified") and r.detail.get("user_id"):
        current = await _assignees(session, c.id)
        await service.assign_field(session, c, [*current, uuid.UUID(r.detail["user_id"])], p)
    c.updated_at = recommend.now()
    await session.flush()
    out = recommend.as_dict(r)
    await session.commit()
    return out


@router.post("/cases/{case_id}/assign")
async def assign(
    case_id: uuid.UUID,
    body: AssignIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    await service.assign(session, c, body.user_id, p)
    return await _done(session, c)


@router.post("/cases/{case_id}/field-assign")
async def field_assign(
    case_id: uuid.UUID,
    body: FieldAssignIn,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    c = await _act(session, case_id, p)
    await service.assign_field(session, c, body.user_ids, p)
    return await _done(session, c)


# ------------------------------------------------------------------ evidence, registry, CCTV


@router.get("/evidence/{evidence_id}/url")
async def evidence_url(
    evidence_id: uuid.UUID,
    request: Request,
    p: Principal = Depends(current_staff),
    session: AsyncSession = Depends(get_session),
) -> dict:
    e = await session.get(Evidence, evidence_id)
    if e is None or e.storage_key is None:
        raise HTTPException(404, "evidence not available")
    obs = await session.get(Observation, e.observation_id)
    case = await case_for_incident(session, obs.incident_id, lock=False)
    require_case_access(p, case, Access.full, await _assignees(session, case.id))
    await audit(session, p, "evidence.view", "evidence", str(e.id), request, case=case.case_number)
    await session.commit()
    return {"url": files.signed_url(e.storage_key), "expires_in": 300, "sha256": e.sha256_verified, "status": e.status}


@router.get("/registry/{serial}")
async def registry_lookup(
    serial: str,
    request: Request,
    p: Principal = Depends(require(*DISPATCH, ROLE_FIELD)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    reg = await session.get(RegistryEntry, serial)
    permits = (
        (
            await session.execute(
                select(Permit).where(json_has(Permit.serials, serial)).order_by(Permit.valid_from.desc()).limit(20)
            )
        )
        .scalars()
        .all()
    )
    await audit(session, p, "registry.lookup", "serial", serial, request, found=reg is not None)
    await session.commit()
    return {
        "serial": serial,
        "registered": reg is not None,
        "entry": {
            "registration_no": reg.registration_no,
            "owner_name": reg.owner_name,
            "owner_ref": reg.owner_ref,
            "model": reg.model,
            "manufacturer": reg.manufacturer,
            "mtow_g": reg.mtow_g,
            "status": reg.status,
        }
        if reg
        else None,
        "permits": [
            {
                "permit_no": x.permit_no,
                "operator_name": x.operator_name,
                "valid_from": x.valid_from.isoformat(),
                "valid_to": x.valid_to.isoformat(),
                "max_alt_m": x.max_alt_m,
                "area": x.area,
            }
            for x in permits
        ],
    }


@router.get("/cctv")
async def cctv_near(
    lat: float,
    lon: float,
    radius_m: float = Query(3000, le=20000),
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    dlat, dlon = bbox_deg(lat, radius_m)
    cams = (
        (
            await session.execute(
                select(CctvCamera).where(
                    CctvCamera.classification <= p.clearance,
                    CctvCamera.lat.between(lat - dlat, lat + dlat),
                    CctvCamera.lon.between(lon - dlon, lon + dlon),
                )
            )
        )
        .scalars()
        .all()
    )
    rows = sorted(((c, distance_m(lat, lon, c.lat, c.lon)) for c in cams), key=lambda x: x[1])
    rows = [(c, d) for c, d in rows if d <= radius_m][:30]
    return [
        {"id": c.id, "name": c.name, "owner": c.owner, "position": latlon(c.lat, c.lon), "distance_m": round(d)}
        for c, d in rows
    ]


@router.get("/cctv/{camera_id}/stream")
async def cctv_stream(
    camera_id: str,
    request: Request,
    case_id: uuid.UUID | None = None,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    cam = await session.get(CctvCamera, camera_id)
    if cam is None or cam.classification > p.clearance:
        raise HTTPException(404, "camera not found")
    await audit(session, p, "cctv.access", "camera", camera_id, request, case=str(case_id) if case_id else None)
    await session.commit()
    return {"stream_url": cam.stream_url, "snapshot_url": cam.snapshot_url}


# ------------------------------------------------------------------ live map


@router.get("/map/live")
async def live_map(
    minutes: int = Query(60, le=24 * 60),
    vessel_minutes: int = Query(30, ge=1, le=7 * 24 * 60),
    p: Principal = Depends(require(*READERS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    since = datetime.now(UTC) - timedelta(minutes=minutes)
    cases = (
        (
            await session.execute(
                select(Case)
                .join(Incident, Incident.id == Case.incident_id)
                .where(
                    _visible_filter(p), or_(Case.state.in_([s.value for s in OPEN_STATES]), Incident.last_seen >= since)
                )
                .limit(2000)
            )
        )
        .unique()
        .scalars()
        .all()
    )
    items = []
    for c in cases:
        a = case_access(p, c)
        if a != Access.none:
            items.append(case_summary(c) if a == Access.full else redacted_summary(c))
    aircraft = (
        (
            await session.execute(
                select(AircraftTrack)
                .where(AircraftTrack.at >= datetime.now(UTC) - timedelta(seconds=60))
                .order_by(AircraftTrack.at.desc())
            )
        )
        .scalars()
        .all()
    )
    aircraft = list({a.icao24: a for a in reversed(aircraft)}.values())  # latest position per aircraft
    officers = (
        (
            await session.execute(
                select(AppUser).where(
                    AppUser.field_unit.is_(True) | json_has(AppUser.roles, ROLE_FIELD),
                    AppUser.last_position_at >= datetime.now(UTC) - timedelta(minutes=15),
                    (AppUser.agency_id == p.agency_id) if not p.has(ROLE_NATIONAL) else true(),
                )
            )
        )
        .scalars()
        .all()
    )
    vessels = (
        (
            await session.execute(
                select(VesselTrack)
                .where(VesselTrack.at >= datetime.now(UTC) - timedelta(minutes=vessel_minutes))
                .order_by(VesselTrack.at.desc())
                .limit(50000)
            )
        )
        .scalars()
        .all()
    )
    # Latest position per vessel / track.
    vessels = list({(v.source_kind, v.mmsi, v.track_id): v for v in reversed(vessels)}.values())[-5000:]
    return {
        "cases": items,
        "vessels": [
            {
                "source_kind": v.source_kind,
                "mmsi": v.mmsi,
                "track_id": v.track_id,
                "name": v.name,
                "ship_type": v.ship_type,
                "role": v.role,
                "role_confidence": v.role_confidence,
                "position": latlon(v.lat, v.lon),
                "sog_kn": v.sog_kn,
                "cog_deg": v.cog_deg,
                "at": v.at.isoformat(),
            }
            for v in vessels
        ],
        "aircraft": [
            {
                "icao24": a.icao24,
                "callsign": a.callsign,
                "position": latlon(a.lat, a.lon),
                "alt_m": a.alt_m,
                "track_deg": a.track_deg,
                "at": a.at.isoformat(),
            }
            for a in aircraft
        ],
        "field_officers": [
            {
                "id": str(u.id),
                "display_name": u.display_name or u.username,
                "position": latlon(u.last_lat, u.last_lon),
                "at": u.last_position_at.isoformat(),
            }
            for u in officers
        ],
    }


@router.get("/video-feeds")
async def video_feeds(p: Principal = Depends(require(*READERS)), session: AsyncSession = Depends(get_session)):
    rows = (
        await session.execute(select(VideoFeed).where(VideoFeed.classification <= p.clearance).order_by(VideoFeed.id))
    ).scalars()
    return [
        {
            "id": f.id,
            "name": f.name,
            "owner": f.owner,
            "position": latlon(f.lat, f.lon),
            "bearing_deg": f.bearing_deg,
            "fov_deg": f.fov_deg,
            "domains": f.domains,
            "active": f.active,
            "sample_interval_s": f.sample_interval_s,
            "last_sampled_at": f.last_sampled_at.isoformat() if f.last_sampled_at else None,
            "last_error": f.last_error,
        }
        for f in rows
    ]


@router.get("/video-feeds/{feed_id}/tracks")
async def video_tracks(
    feed_id: str,
    hours: float = Query(24, gt=0, le=24 * 14),
    p: Principal = Depends(require(*READERS)),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Craft followed across this camera's frames: persistent ids, path in the image, behaviours."""
    f = await session.get(VideoFeed, feed_id)
    if f is None or f.classification > p.clearance:
        raise HTTPException(404, "feed not found")
    since = datetime.now(UTC) - timedelta(hours=hours)
    rows = (
        await session.execute(
            select(VideoTrack)
            .where(VideoTrack.feed_id == feed_id, VideoTrack.last_at >= since)
            .order_by(VideoTrack.last_at.desc())
            .limit(100)
        )
    ).scalars()
    tracks = []
    for t in rows:
        last_frame = next((pt["frame"] for pt in reversed(t.path) if pt.get("frame")), None)
        tracks.append(
            {
                "key": t.key,
                "status": t.status,
                "craft_domain": t.craft_domain,
                "craft_type": t.craft_type,
                "first_at": t.first_at.isoformat(),
                "last_at": t.last_at.isoformat(),
                "hits": t.hits,
                "path": [{k: v for k, v in pt.items() if k != "frame"} for pt in t.path],
                "behaviours": t.behaviours,
                "last_frame_url": files.signed_url(last_frame) if last_frame else None,
            }
        )
    return {
        "feed": {
            "id": f.id,
            "name": f.name,
            "alert_zone": f.alert_zone,
            "bearing_deg": f.bearing_deg,
            "fov_deg": f.fov_deg,
        },
        "tracks": tracks,
    }


@router.get("/video-feeds/{feed_id}/stream")
async def video_feed_stream(
    feed_id: str,
    request: Request,
    case_id: uuid.UUID | None = None,
    p: Principal = Depends(require(*DISPATCH)),
    session: AsyncSession = Depends(get_session),
):
    f = await session.get(VideoFeed, feed_id)
    if f is None or f.classification > p.clearance:
        raise HTTPException(404, "feed not found")
    await audit(session, p, "video_feed.access", "video_feed", feed_id, request, case=str(case_id) if case_id else None)
    await session.commit()
    return {"stream_url": f.stream_url, "snapshot_url": f.snapshot_url}


@router.get("/zones")
async def zones_for_staff(p: Principal = Depends(current_staff), session: AsyncSession = Depends(get_session)) -> dict:
    rows = (await session.execute(select(Zone).where(Zone.active, Zone.classification <= p.clearance))).scalars()
    return {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "id": z.id,
                "properties": {
                    "id": z.id,
                    "code": z.code,
                    "name": z.name,
                    "name_zh": z.name_zh,
                    "zone_type": z.zone_type,
                    "classification": z.classification,
                    "published": z.published,
                    "primary_desk_id": z.primary_desk_id,
                    "backup_chain": z.backup_chain,
                    "priority": z.priority,
                    "ack_timeouts": z.ack_timeouts,
                },
                "geometry": z.geometry,
            }
            for z in rows
        ],
    }


# ------------------------------------------------------------------ field app


@field_router.get("/assignments")
async def assignments(p: Principal = Depends(require(ROLE_FIELD)), session: AsyncSession = Depends(get_session)):
    cases = (
        (
            await session.execute(
                select(Case)
                .join(CaseFieldAssignment, CaseFieldAssignment.case_id == Case.id)
                .where(
                    CaseFieldAssignment.user_id == p.user_id,
                    CaseFieldAssignment.active,
                    Case.state.in_([s.value for s in OPEN_STATES]),
                )
                .order_by(Case.severity.desc(), Case.created_at.desc())
            )
        )
        .unique()
        .scalars()
        .all()
    )
    out = []
    for c in cases:
        a = case_access(p, c, {p.user_id})
        item = case_summary(c) if a == Access.full else redacted_summary(c)
        if a == Access.full:
            item["operator_position"] = latlon(c.incident.operator_lat, c.incident.operator_lon)
        out.append(item)
    return out


@field_router.get("/cases/{case_id}")
async def field_case(
    case_id: uuid.UUID,
    request: Request,
    p: Principal = Depends(require(ROLE_FIELD)),
    session: AsyncSession = Depends(get_session),
):
    c = await _load(session, case_id)
    a = require_case_access(p, c, Access.redacted, await _assignees(session, c.id))
    d = await case_detail(session, c, p, a, request)
    await session.commit()
    return d


@field_router.post("/position", status_code=204)
async def field_position(
    body: PositionIn, p: Principal = Depends(require(ROLE_FIELD)), session: AsyncSession = Depends(get_session)
):
    u = await session.get(AppUser, p.user_id)
    u.last_lat, u.last_lon = body.lat, body.lon
    u.last_position_at = datetime.now(UTC)
    await session.commit()


@field_router.post("/cases/{case_id}/observations", status_code=201)
async def field_observation(
    case_id: uuid.UUID,
    body: FieldObservationIn,
    p: Principal = Depends(require(ROLE_FIELD)),
    session: AsyncSession = Depends(get_session),
):
    """On-scene observation from an officer: attached to the case's incident directly (no clustering)."""
    c = await service.lock_case(session, case_id)
    require_case_access(p, c, Access.full, await _assignees(session, c.id))
    if c.state not in [s.value for s in OPEN_STATES]:
        raise HTTPException(409, "case is not open")
    existing = (
        await session.execute(select(Observation.id).where(Observation.client_report_id == body.client_report_id))
    ).first()
    if existing:
        raise HTTPException(409, "observation already received")
    inc = await session.get(Incident, c.incident_id, with_for_update=True)
    serial = next(
        (m.uas_id for m in sorted(body.remote_id, key=lambda m: m.received_at, reverse=True) if m.uas_id), None
    )
    loc = next(
        (m for m in sorted(body.remote_id, key=lambda m: m.received_at, reverse=True) if m.lat is not None), None
    )
    op = next((m for m in body.remote_id if m.operator_lat is not None), None)
    o = Observation(
        id=uuid.uuid4(),
        client_report_id=body.client_report_id,
        source_type=SourceType.field_officer.value,
        source_id=p.username,
        observed_at=body.observed_at,
        observer_lat=body.observer.lat,
        observer_lon=body.observer.lon,
        observer_accuracy_m=body.observer.accuracy_m,
        bearing_deg=body.bearing_deg,
        elevation_deg=body.elevation_deg,
        confidence=0.8,
        fidelity="high",
        attestation="staff",
        description=body.note,
        description_lang=p.language,
        classification=c.classification,
        craft_domain=inc.craft_domain,
        remote_id_serial=serial,
        raw_payload=body.model_dump(mode="json"),
        schema_version="field-observation/1",
        incident_id=inc.id,
    )
    if body.drone_position:
        o.drone_lat, o.drone_lon = body.drone_position.lat, body.drone_position.lon
        o.altitude_m = body.drone_position.alt_m
    elif loc:
        o.drone_lat, o.drone_lon = loc.lat, loc.lon
        o.altitude_m = loc.height_m if loc.height_m is not None else loc.alt_geo_m
    if op:
        o.operator_lat, o.operator_lon = op.operator_lat, op.operator_lon
    session.add(o)
    evs = [(m.slot, _evidence(o.id, m, "staff")) for m in body.media]
    session.add_all(e for _, e in evs)
    await session.flush()
    await recompute(session, inc)
    await apply_incident_update(session, inc, created=False)
    await session.commit()
    return {"observation_id": str(o.id), "uploads": [t.model_dump(mode="json") for t in _tickets(evs)]}
