"""Case routing: zone -> primary desk (if staffed and cleared) -> backup chain -> national catch-all."""

import json
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import exists, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db.models import AppUser, Case, CaseEvent, Desk, Incident, Zone
from ..domain.enums import CaseAction, CaseState
from ..domain.state import OPEN_STATES
from ..live.bus import publish_case
from ..security.principal import ROLE_DISPATCHER, ROLE_SUPERVISOR


def now() -> datetime:
    return datetime.now(UTC)


async def _catch_all_desks(session: AsyncSession, min_clearance: int) -> list[Desk]:
    return list(
        (
            await session.execute(
                select(Desk).where(Desk.is_catch_all, Desk.clearance >= min_clearance).order_by(Desk.clearance, Desk.id)
            )
        ).scalars()
    )


async def _routing_zone(session: AsyncSession, incident: Incident) -> Zone | None:
    if not incident.matched_zone_ids:
        return None
    return (
        await session.execute(
            select(Zone)
            .where(Zone.id.in_(incident.matched_zone_ids), Zone.primary_desk_id.is_not(None))
            .order_by(Zone.priority.desc(), Zone.classification.desc(), Zone.id)
            .limit(1)
        )
    ).scalar_one_or_none()


async def build_chain(session: AsyncSession, incident: Incident) -> tuple[list[int], Zone | None]:
    zone = await _routing_zone(session, incident)
    chain: list[int] = []
    if zone:
        chain = [zone.primary_desk_id, *(zone.backup_chain or [])]
    # Every chain ends at the national catch-all; classified chains end at a cleared one
    # (the uncleared national desk before it then receives the redacted copy).
    national = await _catch_all_desks(session, 0)
    if national:
        chain.append(national[0].id)
    if incident.classification > 0:
        cleared = await _catch_all_desks(session, incident.classification)
        if cleared:
            chain.append(cleared[0].id)
    seen: set[int] = set()
    return [d for d in chain if not (d in seen or seen.add(d))], zone


async def desk_is_staffed(session: AsyncSession, desk: Desk) -> bool:
    if desk.always_staffed:
        return True
    q = select(
        exists().where(
            AppUser.desk_id == desk.id,
            AppUser.on_duty,
            func.json_overlaps(AppUser.roles, json.dumps([ROLE_DISPATCHER, ROLE_SUPERVISOR])),
        )
    )
    return bool((await session.execute(q)).scalar())


async def pick_desk(
    session: AsyncSession, chain: list[int], start: int, classification: int
) -> tuple[int, list[int], list[str]]:
    """First desk from `start` that is staffed and cleared.

    Returns (index, redacted_desk_ids, skipped_reasons). Uncleared desks that would otherwise have
    received the case get the redacted view.
    """
    desks = {d.id: d for d in (await session.execute(select(Desk).where(Desk.id.in_(chain)))).scalars()}
    redacted: list[int] = []
    reasons: list[str] = []
    first_cleared: int | None = None
    for i in range(start, len(chain)):
        d = desks.get(chain[i])
        if d is None:
            continue
        if d.clearance < classification:
            redacted.append(d.id)
            reasons.append(f"{d.code}:uncleared")
            continue
        if first_cleared is None:
            first_cleared = i
        if await desk_is_staffed(session, d):
            return i, redacted, reasons
        reasons.append(f"{d.code}:unstaffed")
    if first_cleared is not None:
        # Nobody on duty anywhere in the chain: fall back to the first cleared desk.
        return first_cleared, redacted, reasons + ["no_staffed_desk"]
    return len(chain) - 1, redacted, reasons + ["no_cleared_desk"]


def ack_timeout(zone: Zone | None, severity: int) -> timedelta:
    defaults = get_settings().ack_timeouts
    secs = (zone.ack_timeouts or {}).get(str(severity)) if zone else None
    return timedelta(seconds=int(secs or defaults[str(severity)]))


async def _zone_for_case(session: AsyncSession, incident: Incident) -> Zone | None:
    return await _routing_zone(session, incident)


async def next_case_number(session: AsyncSession, at: datetime) -> str:
    # MySQL has no sequences: an atomic counter row, read back via LAST_INSERT_ID on this connection.
    await session.execute(text("UPDATE counter SET value = LAST_INSERT_ID(value + 1) WHERE name = 'case_number'"))
    n = (await session.execute(text("SELECT LAST_INSERT_ID()"))).scalar_one()
    return f"UAV-{at.astimezone(UTC):%y%m%d}-{n:06d}"


def event(case: Case, action: CaseAction, *, actor: str = "system", actor_id: str | None = None, **kw) -> CaseEvent:
    return CaseEvent(case_id=case.id, actor_type=actor, actor_id=actor_id, action=action.value, **kw)


async def open_case(session: AsyncSession, incident: Incident) -> Case:
    t = now()
    chain, zone = await build_chain(session, incident)
    idx, redacted, reasons = await pick_desk(session, chain, 0, incident.classification)
    desk = await session.get(Desk, chain[idx])
    case = Case(
        id=uuid.uuid4(),
        case_number=await next_case_number(session, t),
        incident_id=incident.id,
        agency_id=desk.agency_id,
        desk_id=desk.id,
        state=CaseState.new.value,
        severity=incident.auto_severity,
        classification=incident.classification,
        route_chain=chain,
        route_index=idx,
        redacted_desk_ids=redacted,
        read_agency_ids=[],
        ack_deadline=t + ack_timeout(zone, incident.auto_severity),
        created_at=t,
        updated_at=t,
    )
    session.add(case)
    await session.flush()
    session.add(
        event(
            case,
            CaseAction.created,
            to_state=case.state,
            to_desk_id=desk.id,
            data={"zone": zone.code if zone else None, "skipped": reasons, "severity": case.severity},
        )
    )
    await session.flush()
    case.incident = incident
    case.desk = desk
    await publish_case(session, "case.created", case, field_user_ids=[])
    return case


async def case_for_incident(session: AsyncSession, incident_id: uuid.UUID, lock: bool = True) -> Case | None:
    q = select(Case).where(Case.incident_id == incident_id)
    if lock:
        q = q.with_for_update(of=Case)
    return (await session.execute(q)).unique().scalar_one_or_none()


async def apply_incident_update(session: AsyncSession, incident: Incident, created: bool) -> Case:
    """After fusion: open a case, or propagate severity/classification changes to the existing one."""
    case = None if created else await case_for_incident(session, incident.id)
    if case is None:
        return await open_case(session, incident)

    t = now()
    changed = False
    # Auto-upgrade only: a rule must now demand more than the case currently has.
    if incident.auto_severity > case.severity and case.state in OPEN_STATES:
        old = case.severity
        case.severity = incident.auto_severity
        session.add(
            event(
                case,
                CaseAction.severity_upgraded,
                data={"from": old, "to": case.severity, "reasons": incident.severity_reasons},
            )
        )
        if case.state == CaseState.new.value:
            zone = await _zone_for_case(session, incident)
            case.ack_deadline = t + ack_timeout(zone, case.severity)
        changed = True

    if incident.classification > case.classification:
        case.classification = incident.classification
        changed = True
        desk = await session.get(Desk, case.desk_id)
        if desk.clearance < case.classification and case.state in OPEN_STATES:
            await reroute(session, case, reason="classification_raised", force=True)
            return case

    case.updated_at = t
    session.add(event(case, CaseAction.observation_added, data={"observations": incident.observation_count}))
    await session.flush()
    await publish_case(session, "case.severity" if changed else "case.updated", case)
    return case


async def reroute(session: AsyncSession, case: Case, *, reason: str, force: bool = False) -> None:
    """Move an unacknowledged case to the next eligible desk in its chain (restarts as New)."""
    t = now()
    if case.state != CaseState.new.value and not force:
        return
    old_desk_id, old_agency = case.desk_id, case.agency_id
    chain = case.route_chain or [case.desk_id]
    start = case.route_index + 1
    if start >= len(chain):
        # End of chain (the national catch-all): keep it there, re-alert, restart the timer.
        incident = await session.get(Incident, case.incident_id)
        case.ack_deadline = t + ack_timeout(await _zone_for_case(session, incident), case.severity)
        case.updated_at = t
        session.add(
            event(
                case,
                CaseAction.rerouted,
                from_desk_id=old_desk_id,
                to_desk_id=old_desk_id,
                reason=f"{reason}; end of backup chain",
            )
        )
        await session.flush()
        await publish_case(session, "case.realert", case)
        return

    idx, redacted, reasons = await pick_desk(session, chain, start, case.classification)
    desk = await session.get(Desk, chain[idx])
    from_state = case.state
    case.state = CaseState.new.value
    case.desk_id = desk.id
    case.agency_id = desk.agency_id
    case.route_index = idx
    case.assignee_id = None
    case.redacted_desk_ids = sorted(set(case.redacted_desk_ids or []) | set(redacted))
    if old_agency != desk.agency_id:
        case.read_agency_ids = sorted(set(case.read_agency_ids or []) | {old_agency})
    incident = await session.get(Incident, case.incident_id)
    case.ack_deadline = t + ack_timeout(await _zone_for_case(session, incident), case.severity)
    case.updated_at = t
    session.add(
        event(
            case,
            CaseAction.rerouted,
            from_state=from_state,
            to_state=case.state,
            from_desk_id=old_desk_id,
            to_desk_id=desk.id,
            reason=reason,
            data={"skipped": reasons},
        )
    )
    for d in redacted:
        session.add(event(case, CaseAction.redacted_copy_sent, to_desk_id=d))
    await session.flush()
    await session.refresh(case, ["desk"])
    # The previous desk's agency is notified too (agency_ids includes read_agency_ids).
    await publish_case(session, "case.rerouted", case, extra={"from_desk_id": old_desk_id})


async def overdue_cases(session: AsyncSession, limit: int = 50) -> list[Case]:
    q = (
        select(Case)
        .where(Case.state == CaseState.new.value, Case.ack_deadline < now())
        .order_by(Case.ack_deadline)
        .limit(limit)
        .with_for_update(of=Case, skip_locked=True)
    )
    return list((await session.execute(q)).unique().scalars())
