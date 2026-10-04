import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from ..domain.enums import EvidenceKind

Lang = Literal["zh-TW", "en", "vi", "id", "th", "fil", "de", "fr"]
Sha256 = str


class GeoPoint(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    accuracy_m: float | None = Field(default=None, ge=0, le=100_000)
    alt_m: float | None = None


class RemoteIdMessage(BaseModel):
    """One decoded ASTM F3411 / ASD-STAN message set, as received by the phone."""

    transport: Literal["bt4", "bt5", "wifi_beacon", "wifi_nan", "network"]
    received_at: datetime
    rssi: int | None = None
    uas_id: str | None = Field(default=None, max_length=64)
    id_type: Literal["none", "serial", "caa_registration", "utm_assigned", "specific_session"] | None = None
    ua_type: str | None = Field(default=None, max_length=32)
    lat: float | None = Field(default=None, ge=-90, le=90)
    lon: float | None = Field(default=None, ge=-180, le=180)
    alt_geo_m: float | None = None
    alt_baro_m: float | None = None
    height_m: float | None = None
    speed_mps: float | None = None
    direction_deg: float | None = None
    operator_lat: float | None = Field(default=None, ge=-90, le=90)
    operator_lon: float | None = Field(default=None, ge=-180, le=180)
    operator_id: str | None = Field(default=None, max_length=64)
    self_id_text: str | None = Field(default=None, max_length=64)


class MediaDeclaration(BaseModel):
    slot: str = Field(max_length=32, description="Client-side handle echoed back with the upload URL")
    kind: EvidenceKind
    mime_type: str = Field(max_length=64)
    sha256: Sha256 = Field(pattern=r"^[0-9a-f]{64}$")
    size_bytes: int = Field(gt=0, le=200 * 1024 * 1024)  # matches tusd -max-size
    captured_at: datetime


class ReportIn(BaseModel):
    client_report_id: uuid.UUID
    platform: Literal["android", "web"]
    app_version: str = Field(max_length=32)
    language: Lang = "zh-TW"
    device_id: str = Field(min_length=8, max_length=128, description="Random per-install id, never hardware ids")
    observed_at: datetime
    observer: GeoPoint
    bearing_deg: float | None = Field(default=None, ge=0, lt=360)
    bearing_accuracy_deg: float | None = Field(default=None, ge=0, le=180)
    elevation_deg: float | None = Field(default=None, ge=-10, le=90)
    est_altitude_m: float | None = Field(default=None, ge=0, le=10_000)
    est_distance_m: float | None = Field(default=None, ge=0, le=20_000)
    compass_calibrated: bool | None = None
    drone_count: int | None = Field(default=None, ge=1, le=100)
    movement: Literal["hovering", "moving", "unknown"] | None = None
    craft_domain: Literal["aerial", "surface", "subsurface", "shore", "unknown"] | None = Field(
        default=None, description="Defaults to the interview's domain answer, else aerial"
    )
    interview_version: str | None = Field(default=None, max_length=8)
    interview: dict[str, str] | None = Field(default=None, description="question id -> option value")
    remote_id: list[RemoteIdMessage] = Field(default_factory=list, max_length=200)
    remote_id_transports: list[str] = Field(default_factory=list, max_length=8)
    media: list[MediaDeclaration] = Field(default_factory=list, max_length=10)
    description: str | None = Field(default=None, max_length=1000)
    attestation_token: str | None = Field(default=None, max_length=8192)
    push_token: str | None = Field(default=None, max_length=4096)
    token_secret: str | None = Field(
        default=None,
        min_length=32,
        max_length=128,
        description="Optional client-generated secret (stored before sending, so retries from the offline "
        "queue stay idempotent). The server mints one when absent.",
    )


class UploadTicket(BaseModel):
    slot: str
    evidence_id: uuid.UUID
    upload_url: str
    upload_token: str


class ReportOut(BaseModel):
    case_number: str
    token: str = Field(description="Secret follow-up token. Shown once; store it on the device.")
    status: str
    fidelity: Literal["high", "low"]
    uploads: list[UploadTicket]
    suggest_android_app: bool = False


class EvidenceRequestOut(BaseModel):
    id: uuid.UUID
    template_code: str
    text: str
    requested_kinds: list[str]
    status: str
    created_at: datetime


class TimelineEntry(BaseModel):
    status: str
    at: datetime


class InformantCaseOut(BaseModel):
    case_number: str
    status: str
    outcome_code: str | None
    outcome_text: str | None
    updated_at: datetime
    timeline: list[TimelineEntry]
    evidence_requests: list[EvidenceRequestOut]


class EvidenceResponseIn(BaseModel):
    media: list[MediaDeclaration] = Field(min_length=1, max_length=10)


class PushRegistrationIn(BaseModel):
    push_token: str = Field(max_length=4096)
    platform: Literal["android", "web"] = "android"
    language: Lang | None = None
