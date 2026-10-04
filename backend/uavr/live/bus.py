"""Live updates: every message is a LiveEvent row (seq for resync) plus a NOTIFY on commit."""

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import Case, CaseFieldAssignment, LiveEvent
from ..views import case_summary, redacted_summary


async def publish_case(
    session: AsyncSession,
    kind: str,
    case: Case,
    *,
    extra: dict | None = None,
    field_user_ids: list[uuid.UUID] | None = None,
) -> None:
    """Queue a case update for every desk, agency and field officer entitled to see it."""
    if field_user_ids is None:
        from sqlalchemy import select

        field_user_ids = list(
            (
                await session.execute(
                    select(CaseFieldAssignment.user_id).where(
                        CaseFieldAssignment.case_id == case.id, CaseFieldAssignment.active
                    )
                )
            ).scalars()
        )
    payload = {"case": case_summary(case), **(extra or {})}
    session.add(
        LiveEvent(
            kind=kind,
            case_id=case.id,
            desk_ids=[case.desk_id],
            agency_ids=sorted({case.agency_id, *(case.read_agency_ids or [])}),
            redacted_desk_ids=list(case.redacted_desk_ids or []),
            field_user_ids=[str(u) for u in field_user_ids],
            min_clearance=case.classification,
            payload=payload,
            redacted_payload={"case": redacted_summary(case)},
        )
    )


async def publish_broadcast(session: AsyncSession, kind: str, payload: dict, min_clearance: int = 0) -> None:
    """For messages every console should get (e.g. zone changes)."""
    session.add(LiveEvent(kind=kind, payload=payload, min_clearance=min_clearance, agency_ids=[-1]))
