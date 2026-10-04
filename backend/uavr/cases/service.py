"""Dispatcher actions on cases. Every transition writes a CaseEvent and a LiveEvent."""

import uuid
from datetime import UTC, datetime

from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.dialects.mysql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import (
    Case,
    CaseFieldAssignment,
    Desk,
    DeviceReputation,
    EvidenceRequest,
    Incident,
    InformantCase,
    InformantToken,
    Observation,
    PushOutbox,
    Template,
)
from ..domain.enums import CaseAction, CaseState, Severity, TemplateKind
from ..domain.state import OPEN_STATES, InvalidTransition, next_state
from ..fusion.engine import recompute
from ..live.bus import publish_case
from ..routing.router import ack_timeout, build_chain, event
from ..security import crypto
from ..security.principal import Principal


def _now() -> datetime:
    return datetime.now(UTC)


async def lock_case(session: AsyncSession, case_id: uuid.UUID) -> Case:
    c = (
        (await session.execute(select(Case).where(Case.id == case_id).with_for_update(of=Case)))
        .unique()
        .scalar_one_or_none()
    )
    if c is None:
        raise HTTPException(404, "case not found")
    return c


def _transition(case: Case, action: CaseAction) -> tuple[str, str]:
    try:
        new = next_state(CaseState(case.state), action)
    except InvalidTransition as e:
        raise HTTPException(409, str(e)) from e
    old = case.state
    case.state = new.value
    case.updated_at = _now()
    return old, new.value


async def notify_informants(session: AsyncSession, case: Case) -> None:
    """Queue a content-free push for every informant linked to the case."""
    tokens = (
        await session.execute(
            select(InformantToken.id)
            .join(InformantCase, InformantCase.token_id == InformantToken.id)
            .where(InformantCase.case_id == case.id, InformantToken.push_token.is_not(None))
        )
    ).scalars()
    session.add_all(PushOutbox(token_id=t) for t in tokens)


def _uid(p: Principal) -> str:
    return str(p.user_id)


async def acknowledge(session: AsyncSession, case: Case, p: Principal) -> None:
    old, new = _transition(case, CaseAction.acknowledged)
    case.acked_at = _now()
    case.ack_deadline = None
    case.assignee_id = case.assignee_id or p.user_id
    session.add(event(case, CaseAction.acknowledged, actor="user", actor_id=_uid(p), from_state=old, to_state=new))
    await notify_informants(session, case)
    await session.flush()
    await publish_case(session, "case.acknowledged", case)


async def start_investigation(session: AsyncSession, case: Case, p: Principal) -> None:
    old, new = _transition(case, CaseAction.investigating)
    session.add(event(case, CaseAction.investigating, actor="user", actor_id=_uid(p), from_state=old, to_state=new))
    await notify_informants(session, case)
    await session.flush()
    await publish_case(session, "case.updated", case)


async def transfer(session: AsyncSession, case: Case, to_desk_id: int, reason: str, p: Principal) -> None:
    desk = await session.get(Desk, to_desk_id)
    if desk is None:
        raise HTTPException(404, "desk not found")
    if desk.id == case.desk_id:
        raise HTTPException(409, "case is already at this desk")
    if desk.clearance < case.classification:
        raise HTTPException(409, "target desk is not cleared for this case")
    old_desk, old_agency = case.desk_id, case.agency_id
    old, new = _transition(case, CaseAction.transferred)
    case.desk_id = desk.id
    case.agency_id = desk.agency_id
    case.assignee_id = None
    if old_agency != desk.agency_id:
        case.read_agency_ids = sorted(set(case.read_agency_ids or []) | {old_agency})
    # New chain: the receiving desk, then the incident's normal backups behind it.
    incident = await session.get(Incident, case.incident_id)
    chain, zone = await build_chain(session, incident)
    case.route_chain = [desk.id] + [d for d in chain if d != desk.id]
    case.route_index = 0
    case.ack_deadline = _now() + ack_timeout(zone, case.severity)
    session.add(
        event(
            case,
            CaseAction.transferred,
            actor="user",
            actor_id=_uid(p),
            from_state=old,
            to_state=new,
            from_desk_id=old_desk,
            to_desk_id=desk.id,
            reason=reason,
        )
    )
    await session.flush()
    await session.refresh(case, ["desk"])
    await publish_case(session, "case.transferred", case, extra={"from_desk_id": old_desk})


async def set_severity(session: AsyncSession, case: Case, level: int, reason: str, p: Principal) -> None:
    if case.state not in OPEN_STATES:
        raise HTTPException(409, "case is not open")
    level = int(Severity(level))
    if level == case.severity:
        return
    action = CaseAction.severity_downgraded if level < case.severity else CaseAction.severity_upgraded
    if action == CaseAction.severity_downgraded and not reason.strip():
        raise HTTPException(422, "a downgrade needs a reason")
    old = case.severity
    case.severity = level
    case.updated_at = _now()
    if action == CaseAction.severity_upgraded and case.state == CaseState.new.value:
        incident = await session.get(Incident, case.incident_id)
        _, zone = await build_chain(session, incident)
        case.ack_deadline = _now() + ack_timeout(zone, level)
    session.add(event(case, action, actor="user", actor_id=_uid(p), reason=reason, data={"from": old, "to": level}))
    await session.flush()
    await publish_case(session, "case.severity", case)


async def resolve(session: AsyncSession, case: Case, outcome_code: str, note: str | None, p: Principal) -> None:
    t = await session.get(Template, outcome_code)
    if t is None or t.kind != TemplateKind.outcome.value or not t.active:
        raise HTTPException(422, "unknown outcome template")
    old, new = _transition(case, CaseAction.resolved)
    case.outcome_code = outcome_code
    case.outcome_note = note
    case.resolved_at = _now()
    session.add(
        event(
            case,
            CaseAction.resolved,
            actor="user",
            actor_id=_uid(p),
            from_state=old,
            to_state=new,
            data={"outcome": outcome_code},
        )
    )
    # Feed device reputation: false reports lower future confidence for those devices.
    devices = (
        (
            await session.execute(
                select(Observation.device_hash)
                .distinct()
                .where(Observation.incident_id == case.incident_id, Observation.device_hash.is_not(None))
            )
        )
        .scalars()
        .all()
    )
    col = "false_reports" if t.counts_as_false_report else "confirmed_reports"
    for d in devices:
        stmt = insert(DeviceReputation).values(device_hash=d, **{col: 1})
        stmt = stmt.on_duplicate_key_update({col: getattr(DeviceReputation, col) + 1, "updated_at": _now()})
        await session.execute(stmt)
    if t.counts_as_false_report:
        await session.execute(
            update(DeviceReputation)
            .where(
                DeviceReputation.device_hash.in_(devices),
                DeviceReputation.false_reports >= 5,
                DeviceReputation.false_reports > DeviceReputation.confirmed_reports * 2,
            )
            .values(flagged=True, reason="repeated false reports")
        )
    await session.execute(update(Incident).where(Incident.id == case.incident_id).values(active=False))
    await notify_informants(session, case)
    await session.flush()
    await publish_case(session, "case.resolved", case)


async def close(session: AsyncSession, case: Case, p: Principal | None) -> None:
    old, new = _transition(case, CaseAction.closed)
    case.closed_at = _now()
    session.add(
        event(
            case,
            CaseAction.closed,
            actor="user" if p else "system",
            actor_id=_uid(p) if p else None,
            from_state=old,
            to_state=new,
        )
    )
    await session.flush()
    await publish_case(session, "case.closed", case)


async def merge(session: AsyncSession, survivor: Case, absorbed: Case, reason: str, p: Principal) -> None:
    """Fold `absorbed` into `survivor` (same drone). Observations and informants move over."""
    if survivor.id == absorbed.id:
        raise HTTPException(409, "cannot merge a case into itself")
    if survivor.state not in OPEN_STATES:
        raise HTTPException(409, "surviving case must be open")
    old, new = _transition(absorbed, CaseAction.merged)
    absorbed.merged_into_id = survivor.id
    absorbed.ack_deadline = None
    inc_s = await session.get(Incident, survivor.incident_id, with_for_update=True)
    inc_a = await session.get(Incident, absorbed.incident_id, with_for_update=True)
    await session.execute(update(Observation).where(Observation.incident_id == inc_a.id).values(incident_id=inc_s.id))
    inc_a.merged_into_id = inc_s.id
    inc_a.active = False
    links = (
        await session.execute(select(InformantCase.token_id).where(InformantCase.case_id == absorbed.id))
    ).scalars()
    for tid in links:
        await session.execute(insert(InformantCase).values(token_id=tid, case_id=survivor.id).prefix_with("IGNORE"))
    await session.execute(
        update(EvidenceRequest).where(EvidenceRequest.case_id == absorbed.id).values(case_id=survivor.id)
    )
    inc_s.first_seen = min(inc_s.first_seen, inc_a.first_seen)
    await recompute(session, inc_s)
    survivor.severity = max(survivor.severity, absorbed.severity, inc_s.auto_severity)
    survivor.classification = max(survivor.classification, absorbed.classification, inc_s.classification)
    survivor.read_agency_ids = sorted(
        set(survivor.read_agency_ids or []) | set(absorbed.read_agency_ids or []) | {absorbed.agency_id}
    )
    survivor.read_agency_ids = [a for a in survivor.read_agency_ids if a != survivor.agency_id]
    survivor.updated_at = _now()
    session.add(
        event(
            absorbed,
            CaseAction.merged,
            actor="user",
            actor_id=_uid(p),
            from_state=old,
            to_state=new,
            reason=reason,
            data={"into": survivor.case_number},
        )
    )
    session.add(
        event(
            survivor,
            CaseAction.merged_from,
            actor="user",
            actor_id=_uid(p),
            reason=reason,
            data={"from": absorbed.case_number},
        )
    )
    await session.flush()
    await publish_case(session, "case.merged", absorbed, extra={"into": str(survivor.id)})
    await publish_case(session, "case.updated", survivor)


async def request_evidence(session: AsyncSession, case: Case, template_code: str, p: Principal) -> int:
    t = await session.get(Template, template_code)
    if t is None or t.kind != TemplateKind.evidence_request.value or not t.active:
        raise HTTPException(422, "unknown evidence request template")
    if case.state not in OPEN_STATES:
        raise HTTPException(409, "case is not open")
    tokens = (
        (await session.execute(select(InformantCase.token_id).where(InformantCase.case_id == case.id))).scalars().all()
    )
    for tid in tokens:
        session.add(EvidenceRequest(case_id=case.id, token_id=tid, template_code=template_code, created_by=p.user_id))
    session.add(
        event(
            case,
            CaseAction.evidence_requested,
            actor="user",
            actor_id=_uid(p),
            data={"template": template_code, "informants": len(tokens)},
        )
    )
    await notify_informants(session, case)
    await session.flush()
    await publish_case(session, "case.updated", case)
    return len(tokens)


async def add_note(session: AsyncSession, case: Case, text: str, defense: bool, p: Principal) -> None:
    if defense:
        if p.clearance < 2:
            raise HTTPException(403, "defense notes need defense clearance")
        existing = crypto.decrypt(case.defense_notes_enc, case.id.bytes) if case.defense_notes_enc else ""
        stamp = f"[{_now():%Y-%m-%d %H:%M} {p.username}] "
        case.defense_notes_enc = crypto.encrypt(existing + stamp + text + "\n", case.id.bytes)
        session.add(event(case, CaseAction.note, actor="user", actor_id=_uid(p), data={"defense": True}))
    else:
        session.add(event(case, CaseAction.note, actor="user", actor_id=_uid(p), reason=text))
    case.updated_at = _now()
    await session.flush()
    await publish_case(session, "case.updated", case)


async def assign(session: AsyncSession, case: Case, user_id: uuid.UUID | None, p: Principal) -> None:
    case.assignee_id = user_id
    case.updated_at = _now()
    session.add(
        event(
            case,
            CaseAction.assigned,
            actor="user",
            actor_id=_uid(p),
            data={"assignee": str(user_id) if user_id else None},
        )
    )
    await session.flush()
    await publish_case(session, "case.updated", case)


async def assign_field(session: AsyncSession, case: Case, user_ids: list[uuid.UUID], p: Principal) -> None:
    await session.execute(
        update(CaseFieldAssignment).where(CaseFieldAssignment.case_id == case.id).values(active=False)
    )
    for uid in user_ids:
        await session.execute(
            insert(CaseFieldAssignment)
            .values(case_id=case.id, user_id=uid, active=True)
            .on_duplicate_key_update(active=True)
        )
    session.add(
        event(
            case,
            CaseAction.field_assigned,
            actor="user",
            actor_id=_uid(p),
            data={"officers": [str(u) for u in user_ids]},
        )
    )
    await session.flush()
    await publish_case(session, "case.field_assigned", case, field_user_ids=user_ids)
