import uuid
from dataclasses import dataclass, field

ROLE_DISPATCHER = "dispatcher"
ROLE_SUPERVISOR = "supervisor"
ROLE_ANALYST = "analyst"
ROLE_FIELD = "field_officer"
ROLE_ADMIN = "admin"
ROLE_NATIONAL = "national"  # national command centre: sees every agency's cases (within clearance)
STAFF_ROLES = {ROLE_DISPATCHER, ROLE_SUPERVISOR, ROLE_ANALYST, ROLE_FIELD, ROLE_ADMIN, ROLE_NATIONAL}


@dataclass(frozen=True)
class Principal:
    user_id: uuid.UUID
    username: str
    display_name: str
    agency_id: int | None
    desk_id: int | None
    roles: frozenset[str] = field(default_factory=frozenset)
    clearance: int = 0
    field_unit: bool = False
    language: str = "zh-TW"

    def has(self, *roles: str) -> bool:
        return bool(self.roles.intersection(roles))
