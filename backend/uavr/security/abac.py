"""Attribute-based access: role x agency x clearance x the case's classification label."""

import uuid
from enum import IntEnum

from fastapi import HTTPException, status

from ..db.models import Case
from .principal import (
    ROLE_ANALYST,
    ROLE_DISPATCHER,
    ROLE_FIELD,
    ROLE_NATIONAL,
    ROLE_SUPERVISOR,
    Principal,
)


class Access(IntEnum):
    none = 0
    redacted = 1
    full = 2


def case_access(p: Principal, case: Case, field_assignees: set[uuid.UUID] | None = None) -> Access:
    cleared = p.clearance >= case.classification
    involved = False
    if p.has(ROLE_NATIONAL):
        involved = True
    elif p.has(ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_ANALYST) and p.agency_id is not None:
        involved = p.agency_id == case.agency_id or p.agency_id in (case.read_agency_ids or [])
    if not involved and p.has(ROLE_FIELD) and field_assignees and p.user_id in field_assignees:
        involved = True
        # Defense details reach the field app only for defense field units.
        cleared = cleared and (case.classification < 2 or p.field_unit)
    if involved:
        return Access.full if cleared else Access.redacted
    if p.desk_id is not None and p.desk_id in (case.redacted_desk_ids or []):
        return Access.redacted
    return Access.none


def require_case_access(p: Principal, case: Case, minimum: Access = Access.full, assignees=None) -> Access:
    a = case_access(p, case, assignees)
    if a < minimum:
        if a == Access.none:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "case not found")
        raise HTTPException(status.HTTP_403_FORBIDDEN, "insufficient clearance for this case")
    return a


def can_act(p: Principal, case: Case) -> bool:
    """Case actions belong to the desk currently holding the case (or its agency's supervisors)."""
    if p.clearance < case.classification:
        return False
    if p.has(ROLE_DISPATCHER) and p.desk_id == case.desk_id:
        return True
    if p.has(ROLE_SUPERVISOR) and p.agency_id == case.agency_id:
        return True
    # National command supervisors can step in on any case they are cleared for.
    return p.has(ROLE_NATIONAL) and p.has(ROLE_SUPERVISOR)


def require_act(p: Principal, case: Case) -> None:
    if not can_act(p, case):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "only the desk holding this case can act on it")


def sees_sensitive_fields(p: Principal) -> bool:
    """Sensor positions and defense notes need at least 'restricted' clearance."""
    return p.clearance >= 1
