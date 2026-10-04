import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from .report_schemas import GeoPoint, MediaDeclaration, RemoteIdMessage


class DutyIn(BaseModel):
    on_duty: bool


class TransferIn(BaseModel):
    desk_id: int
    reason: str = Field(min_length=1, max_length=500)


class MergeIn(BaseModel):
    other_case_id: uuid.UUID
    reason: str = Field(default="same drone", max_length=500)


class SeverityIn(BaseModel):
    severity: Literal[1, 2, 3]
    reason: str = Field(default="", max_length=500)


class ResolveIn(BaseModel):
    outcome_code: str
    note: str | None = Field(default=None, max_length=4000)


class EvidenceRequestIn(BaseModel):
    template_code: str


class NoteIn(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
    defense: bool = False


class AssignIn(BaseModel):
    user_id: uuid.UUID | None


class FieldAssignIn(BaseModel):
    user_ids: list[uuid.UUID] = Field(max_length=20)


class PositionIn(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    accuracy_m: float | None = None


class FieldObservationIn(BaseModel):
    client_report_id: uuid.UUID
    observed_at: datetime
    observer: GeoPoint
    bearing_deg: float | None = Field(default=None, ge=0, lt=360)
    elevation_deg: float | None = Field(default=None, ge=-10, le=90)
    drone_position: GeoPoint | None = None
    remote_id: list[RemoteIdMessage] = Field(default_factory=list, max_length=500)
    media: list[MediaDeclaration] = Field(default_factory=list, max_length=20)
    note: str | None = Field(default=None, max_length=4000)


class ZoneIn(BaseModel):
    code: str = Field(max_length=64)
    name: str
    name_zh: str
    zone_type: str
    classification: int = Field(ge=0, le=2, default=0)
    published: bool = False
    priority: int = 0
    geometry: dict
    primary_desk_id: int | None = None
    backup_chain: list[int] = Field(default_factory=list)
    ack_timeouts: dict[str, int] = Field(default_factory=dict)
    domains: list[str] = Field(default_factory=lambda: ["aerial", "surface", "subsurface", "shore"])
    active: bool = True


class DeskIn(BaseModel):
    agency_id: int
    code: str
    name: str
    name_zh: str
    clearance: int = Field(ge=0, le=2, default=0)
    is_catch_all: bool = False
    always_staffed: bool = False


class TemplateIn(BaseModel):
    code: str = Field(max_length=48)
    kind: Literal["outcome", "evidence_request"]
    texts: dict[str, str]
    counts_as_false_report: bool = False
    requested_kinds: list[str] = Field(default_factory=list)
    sort: int = 0
    active: bool = True


class FeedClientIn(BaseModel):
    name: str
    sources: list[str]
    classification: int = Field(ge=0, le=2, default=0)


class UserUpdateIn(BaseModel):
    display_name: str = Field(default="", max_length=200)
    roles: list[str]
    agency_id: int | None = None
    desk_id: int | None = None
    clearance: int = Field(ge=0, le=2, default=0)
    field_unit: bool = False
    language: str = Field(default="zh-TW", max_length=8)
    password: str | None = Field(default=None, max_length=256)  # set to reset
    active: bool | None = None


class UserIn(UserUpdateIn):
    username: str = Field(min_length=3, max_length=128, pattern=r"^[A-Za-z0-9._@-]+$")
    password: str = Field(max_length=256)
