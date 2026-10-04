"""Relational model (MySQL 8).

Positions are plain latitude/longitude DOUBLE columns (indexed for bounding-box prefilters); polygons and tracks
are GeoJSON / coordinate lists in JSON columns. Distances and point-in-polygon tests run in Python (uavr/geoutil.py),
which keeps the schema portable and avoids MySQL's latitude-first axis order for SRID 4326.
Lists (roles, routing chains, zone ids, serials) are JSON arrays.

Evidence tier: observation, evidence (+ files in UAVR_DATA_DIR). Analytics tier: v_* views.
"""

import uuid
from datetime import UTC, datetime

from sqlalchemy import (
    JSON,
    VARBINARY,
    BigInteger,
    Boolean,
    Double,
    ForeignKey,
    Index,
    Integer,
    LargeBinary,
    SmallInteger,
    String,
    Text,
    TypeDecorator,
    UniqueConstraint,
    Uuid,
    text,
)
from sqlalchemy.dialects.mysql import DATETIME
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class UTCDateTime(TypeDecorator):
    """DATETIME(6) holding UTC. Python side is always timezone-aware (connections run with time_zone '+00:00')."""

    impl = DATETIME(fsp=6)
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None and value.tzinfo is not None:
            value = value.astimezone(UTC).replace(tzinfo=None)
        return value

    def process_result_value(self, value, dialect):
        return value.replace(tzinfo=UTC) if value is not None else None


NOW = text("CURRENT_TIMESTAMP(6)")
Hash = VARBINARY(32)


def _uuid() -> uuid.UUID:
    return uuid.uuid4()


def _created() -> Mapped[datetime]:
    return mapped_column(UTCDateTime, server_default=NOW)


# ---------------------------------------------------------------- organization


class Agency(Base):
    __tablename__ = "agency"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(32), unique=True)
    name: Mapped[str] = mapped_column(String(200))
    name_zh: Mapped[str] = mapped_column(String(200))
    kind: Mapped[str] = mapped_column(String(16))  # police | caa | defense | coast_guard | national
    created_at: Mapped[datetime] = _created()


class Desk(Base):
    __tablename__ = "desk"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    agency_id: Mapped[int] = mapped_column(ForeignKey("agency.id"))
    code: Mapped[str] = mapped_column(String(48), unique=True)
    name: Mapped[str] = mapped_column(String(200))
    name_zh: Mapped[str] = mapped_column(String(200))
    clearance: Mapped[int] = mapped_column(SmallInteger, default=0)
    is_catch_all: Mapped[bool] = mapped_column(Boolean, default=False)
    # A desk staffed 24/7 by contract is eligible even when nobody is logged in as on duty.
    always_staffed: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = _created()
    agency: Mapped[Agency] = relationship(lazy="joined")


class AppUser(Base):
    """Staff account. Login is built in (username + password); attributes drive ABAC."""

    __tablename__ = "app_user"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    username: Mapped[str] = mapped_column(String(128), unique=True)
    display_name: Mapped[str] = mapped_column(String(200), default="")
    password_hash: Mapped[str | None] = mapped_column(String(255))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    failed_logins: Mapped[int] = mapped_column(SmallInteger, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(UTCDateTime)
    password_changed_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    agency_id: Mapped[int | None] = mapped_column(ForeignKey("agency.id"))
    desk_id: Mapped[int | None] = mapped_column(ForeignKey("desk.id"))
    roles: Mapped[list[str]] = mapped_column(JSON, default=list)
    clearance: Mapped[int] = mapped_column(SmallInteger, default=0)
    field_unit: Mapped[bool] = mapped_column(Boolean, default=False)
    language: Mapped[str] = mapped_column(String(8), default="zh-TW")
    on_duty: Mapped[bool] = mapped_column(Boolean, default=False)
    on_duty_since: Mapped[datetime | None] = mapped_column(UTCDateTime)
    last_seen: Mapped[datetime | None] = mapped_column(UTCDateTime)
    last_lat: Mapped[float | None] = mapped_column(Double)  # field officers
    last_lon: Mapped[float | None] = mapped_column(Double)
    last_position_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    created_at: Mapped[datetime] = _created()


class StaffSession(Base):
    """Refresh token (hashed). Revoked on logout, password change or deactivation."""

    __tablename__ = "staff_session"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("app_user.id"), index=True)
    token_hash: Mapped[bytes] = mapped_column(Hash, unique=True)
    client: Mapped[str | None] = mapped_column(String(32))  # console | field
    created_at: Mapped[datetime] = _created()
    expires_at: Mapped[datetime] = mapped_column(UTCDateTime)
    last_used: Mapped[datetime | None] = mapped_column(UTCDateTime)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)


# ---------------------------------------------------------------- zones


class Zone(Base):
    __tablename__ = "zone"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(64), unique=True)
    name: Mapped[str] = mapped_column(String(200))
    name_zh: Mapped[str] = mapped_column(String(200))
    zone_type: Mapped[str] = mapped_column(String(32))
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)
    # Only published CAA zones are sent to the informant app.
    published: Mapped[bool] = mapped_column(Boolean, default=False)
    priority: Mapped[int] = mapped_column(SmallInteger, default=0)  # higher wins when routing
    geometry: Mapped[dict] = mapped_column(JSON)  # GeoJSON Polygon / MultiPolygon (lon, lat)
    # Bounding box for quick prefilters.
    min_lat: Mapped[float] = mapped_column(Double)
    min_lon: Mapped[float] = mapped_column(Double)
    max_lat: Mapped[float] = mapped_column(Double)
    max_lon: Mapped[float] = mapped_column(Double)
    primary_desk_id: Mapped[int | None] = mapped_column(ForeignKey("desk.id"))
    backup_chain: Mapped[list[int]] = mapped_column(JSON, default=list)
    # {"3": 120, "2": 600, "1": 3600}; missing keys fall back to settings.ack_timeouts
    ack_timeouts: Mapped[dict] = mapped_column(JSON, default=dict)
    # Craft domains the zone applies to (routing and severity), e.g. airports: aerial only.
    domains: Mapped[list[str]] = mapped_column(JSON, default=lambda: ["aerial", "surface", "subsurface", "shore"])
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_at: Mapped[datetime] = _created()


# ---------------------------------------------------------------- informants


class InformantToken(Base):
    """Anonymous follow-up credential. The secret is only ever stored as an HMAC."""

    __tablename__ = "informant_token"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    secret_hash: Mapped[bytes] = mapped_column(Hash)
    language: Mapped[str] = mapped_column(String(8), default="zh-TW")
    push_token: Mapped[str | None] = mapped_column(Text)
    push_platform: Mapped[str | None] = mapped_column(String(16))
    last_seen: Mapped[datetime | None] = mapped_column(UTCDateTime)
    created_at: Mapped[datetime] = _created()


class InformantCase(Base):
    __tablename__ = "informant_case"
    token_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("informant_token.id"), primary_key=True)
    case_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cases.id"), primary_key=True)


class DeviceReputation(Base):
    __tablename__ = "device_reputation"
    device_hash: Mapped[bytes] = mapped_column(Hash, primary_key=True)
    flagged: Mapped[bool] = mapped_column(Boolean, default=False)
    reason: Mapped[str | None] = mapped_column(Text)
    false_reports: Mapped[int] = mapped_column(Integer, default=0)
    confirmed_reports: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = _created()


class RateCounter(Base):
    __tablename__ = "rate_counter"
    key: Mapped[bytes] = mapped_column(VARBINARY(40), primary_key=True)
    window_start: Mapped[datetime] = mapped_column(UTCDateTime, primary_key=True)
    count: Mapped[int] = mapped_column(Integer, default=0)


class Counter(Base):
    """Named counters (MySQL has no sequences): case numbers."""

    __tablename__ = "counter"
    name: Mapped[str] = mapped_column(String(32), primary_key=True)
    value: Mapped[int] = mapped_column(BigInteger, default=0)


# ---------------------------------------------------------------- observations


class Observation(Base):
    __tablename__ = "observation"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    source_type: Mapped[str] = mapped_column(String(24), index=True)
    source_id: Mapped[str | None] = mapped_column(String(128), index=True)  # sensor/receiver/feed/officer
    # Client-generated id so a retried submission (offline queue, flaky network) is not duplicated.
    client_report_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, unique=True)
    observed_at: Mapped[datetime] = mapped_column(UTCDateTime, index=True)
    received_at: Mapped[datetime] = _created()
    # Observer (informant / officer / sensor / camera) and, when known, the craft and its operator.
    observer_lat: Mapped[float | None] = mapped_column(Double)
    observer_lon: Mapped[float | None] = mapped_column(Double)
    observer_accuracy_m: Mapped[float | None] = mapped_column(Double)
    drone_lat: Mapped[float | None] = mapped_column(Double)
    drone_lon: Mapped[float | None] = mapped_column(Double)
    operator_lat: Mapped[float | None] = mapped_column(Double)
    operator_lon: Mapped[float | None] = mapped_column(Double)
    bearing_deg: Mapped[float | None] = mapped_column(Double)
    bearing_accuracy_deg: Mapped[float | None] = mapped_column(Double)
    elevation_deg: Mapped[float | None] = mapped_column(Double)
    altitude_m: Mapped[float | None] = mapped_column(Double)
    altitude_source: Mapped[str | None] = mapped_column(String(24))
    track: Mapped[list | None] = mapped_column(JSON)  # sensor tracks: [[lat, lon, alt], ...]
    remote_id_serial: Mapped[str | None] = mapped_column(String(64), index=True)
    remote_id: Mapped[dict | None] = mapped_column(JSON)
    confidence: Mapped[float] = mapped_column(Double, default=0.5)
    spam_score: Mapped[float] = mapped_column(Double, default=0.0)
    fidelity: Mapped[str | None] = mapped_column(String(8))  # high | low
    attestation: Mapped[str | None] = mapped_column(String(24))  # passed | failed | unavailable | skipped
    device_hash: Mapped[bytes | None] = mapped_column(Hash, index=True)
    network_hash: Mapped[bytes | None] = mapped_column(Hash)
    description: Mapped[str | None] = mapped_column(Text)
    description_lang: Mapped[str | None] = mapped_column(String(8))
    description_translations: Mapped[dict] = mapped_column(JSON, default=dict)
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)
    craft_domain: Mapped[str] = mapped_column(String(16), default="aerial", server_default="aerial")
    craft_type: Mapped[str | None] = mapped_column(String(32))
    interview: Mapped[dict | None] = mapped_column(JSON)  # structured interview answers (versioned)
    ai_assessment: Mapped[dict | None] = mapped_column(JSON)  # advisory, model output validated
    raw_payload: Mapped[dict] = mapped_column(JSON)
    schema_version: Mapped[str] = mapped_column(String(48))
    incident_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("incident.id"), index=True)
    informant_token_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("informant_token.id"))
    evidence: Mapped[list["Evidence"]] = relationship(back_populates="observation", lazy="selectin")


class Evidence(Base):
    __tablename__ = "evidence"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    observation_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("observation.id"), index=True)
    evidence_request_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("evidence_request.id"))
    kind: Mapped[str] = mapped_column(String(8))
    mime_type: Mapped[str | None] = mapped_column(String(64))
    sha256_declared: Mapped[str] = mapped_column(String(64), index=True)
    sha256_verified: Mapped[str | None] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(16), default="pending")
    size_bytes: Mapped[int | None] = mapped_column(BigInteger)
    captured_at: Mapped[datetime] = mapped_column(UTCDateTime)
    uploaded_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    attestation: Mapped[str | None] = mapped_column(String(24))
    storage_key: Mapped[str | None] = mapped_column(String(255))  # path relative to UAVR_DATA_DIR
    tus_upload_id: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = _created()
    observation: Mapped[Observation] = relationship(back_populates="evidence")


# ---------------------------------------------------------------- incidents and cases


class Incident(Base):
    __tablename__ = "incident"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    first_seen: Mapped[datetime] = mapped_column(UTCDateTime)
    last_seen: Mapped[datetime] = mapped_column(UTCDateTime, index=True)
    est_lat: Mapped[float | None] = mapped_column(Double)
    est_lon: Mapped[float | None] = mapped_column(Double)
    position_source: Mapped[str | None] = mapped_column(String(24))
    est_error_m: Mapped[float | None] = mapped_column(Double)
    est_altitude_m: Mapped[float | None] = mapped_column(Double)
    track: Mapped[list | None] = mapped_column(JSON)  # [[lat, lon], ...]
    operator_lat: Mapped[float | None] = mapped_column(Double)
    operator_lon: Mapped[float | None] = mapped_column(Double)
    auto_severity: Mapped[int] = mapped_column(SmallInteger, default=1)
    severity_reasons: Mapped[list[str]] = mapped_column(JSON, default=list)
    confidence: Mapped[float] = mapped_column(Double, default=0.0)
    matched_zone_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    remote_id_serials: Mapped[list[str]] = mapped_column(JSON, default=list)
    authorization: Mapped[str] = mapped_column(String(24), default="unknown")
    permit_id: Mapped[int | None] = mapped_column(ForeignKey("permit.id"))
    registry_serial: Mapped[str | None] = mapped_column(String(64))
    adsb_nearby: Mapped[list] = mapped_column(JSON, default=list)
    weather: Mapped[dict | None] = mapped_column(JSON)
    observation_count: Mapped[int] = mapped_column(Integer, default=0)
    distinct_informants: Mapped[int] = mapped_column(Integer, default=0)
    sensor_confirmed: Mapped[bool] = mapped_column(Boolean, default=False)
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)
    craft_domain: Mapped[str] = mapped_column(String(16), default="aerial", server_default="aerial")
    craft_type: Mapped[str | None] = mapped_column(String(32))
    ai_assessment: Mapped[dict | None] = mapped_column(JSON)
    # Surface incidents: nearest AIS vessel, or {"dark": true} when nothing transmits nearby.
    vessel_match: Mapped[dict | None] = mapped_column(JSON)
    merged_into_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("incident.id"))


class Case(Base):
    __tablename__ = "cases"  # "case" is a reserved word in MySQL
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    case_number: Mapped[str] = mapped_column(String(24), unique=True)
    incident_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("incident.id"), unique=True)
    agency_id: Mapped[int] = mapped_column(ForeignKey("agency.id"), index=True)
    desk_id: Mapped[int] = mapped_column(ForeignKey("desk.id"), index=True)
    state: Mapped[str] = mapped_column(String(16), index=True, default="new")
    severity: Mapped[int] = mapped_column(SmallInteger, default=1)
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)
    assignee_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("app_user.id"))
    ack_deadline: Mapped[datetime | None] = mapped_column(UTCDateTime, index=True)
    route_index: Mapped[int] = mapped_column(SmallInteger, default=0)  # position in the routing chain
    route_chain: Mapped[list[int]] = mapped_column(JSON, default=list)
    # Agencies that held the case before re-route/transfer keep read access.
    read_agency_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    # Uncleared desks that only receive the redacted view of a classified case.
    redacted_desk_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    outcome_code: Mapped[str | None] = mapped_column(String(48))
    outcome_note: Mapped[str | None] = mapped_column(Text)  # internal only, never shown to informants
    defense_notes_enc: Mapped[bytes | None] = mapped_column(LargeBinary)
    merged_into_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("cases.id"))
    created_at: Mapped[datetime] = _created()
    updated_at: Mapped[datetime] = _created()
    acked_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    resolved_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    closed_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    incident: Mapped[Incident] = relationship(lazy="joined")
    desk: Mapped[Desk] = relationship(lazy="joined")


class CaseEvent(Base):
    """Append-only audit trail; triggers reject UPDATE and DELETE."""

    __tablename__ = "case_event"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    case_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cases.id"), index=True)
    at: Mapped[datetime] = mapped_column(UTCDateTime, server_default=NOW, index=True)
    actor_type: Mapped[str] = mapped_column(String(16))  # system | user | informant
    actor_id: Mapped[str | None] = mapped_column(String(64))
    action: Mapped[str] = mapped_column(String(32))
    from_state: Mapped[str | None] = mapped_column(String(16))
    to_state: Mapped[str | None] = mapped_column(String(16))
    from_desk_id: Mapped[int | None] = mapped_column(Integer)
    to_desk_id: Mapped[int | None] = mapped_column(Integer)
    reason: Mapped[str | None] = mapped_column(Text)
    data: Mapped[dict] = mapped_column(JSON, default=dict)


class CaseRecommendation(Base):
    """Suggested response for a case (decision support only: nothing here controls a device).

    The operator accepts, rejects or modifies each one; every decision is also a case_event.
    """

    __tablename__ = "case_recommendation"
    __table_args__ = (UniqueConstraint("case_id", "code", name="uq_case_recommendation"),)
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    case_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cases.id"), index=True)
    code: Mapped[str] = mapped_column(String(80))  # kind[:target], e.g. camera:CAM-12, field:<user id>
    kind: Mapped[str] = mapped_column(String(24))
    priority: Mapped[int] = mapped_column(SmallInteger)  # lower first
    text: Mapped[str] = mapped_column(Text)
    reason: Mapped[str] = mapped_column(Text)
    detail: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(16), default="proposed")  # proposed|accepted|rejected|modified
    final_text: Mapped[str | None] = mapped_column(Text)
    note: Mapped[str | None] = mapped_column(Text)
    decided_by: Mapped[str | None] = mapped_column(String(64))
    decided_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    created_at: Mapped[datetime] = _created()


class CaseFieldAssignment(Base):
    __tablename__ = "case_field_assignment"
    case_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cases.id"), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("app_user.id"), primary_key=True)
    assigned_at: Mapped[datetime] = _created()
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Template(Base):
    """Pre-translated informant-facing texts. Dispatchers can only pick from these."""

    __tablename__ = "template"
    code: Mapped[str] = mapped_column(String(48), primary_key=True)
    kind: Mapped[str] = mapped_column(String(24))
    texts: Mapped[dict] = mapped_column(JSON)  # {"zh-TW": "...", "en": "...", ...}
    counts_as_false_report: Mapped[bool] = mapped_column(Boolean, default=False)
    requested_kinds: Mapped[list[str]] = mapped_column(JSON, default=list)
    sort: Mapped[int] = mapped_column(SmallInteger, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class EvidenceRequest(Base):
    __tablename__ = "evidence_request"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=_uuid)
    case_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cases.id"), index=True)
    token_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("informant_token.id"), index=True)
    template_code: Mapped[str] = mapped_column(ForeignKey("template.code"))
    created_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("app_user.id"))
    created_at: Mapped[datetime] = _created()
    status: Mapped[str] = mapped_column(String(16), default="open")  # open | answered | cancelled
    answered_at: Mapped[datetime | None] = mapped_column(UTCDateTime)


# ---------------------------------------------------------------- lookups and context


class RegistryEntry(Base):
    __tablename__ = "registry_entry"
    serial: Mapped[str] = mapped_column(String(64), primary_key=True)
    registration_no: Mapped[str | None] = mapped_column(String(64))
    owner_name: Mapped[str | None] = mapped_column(String(200))
    owner_ref: Mapped[str | None] = mapped_column(String(128))  # CAA owner key, groups repeat offenders
    model: Mapped[str | None] = mapped_column(String(200))
    manufacturer: Mapped[str | None] = mapped_column(String(200))
    mtow_g: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str | None] = mapped_column(String(24))
    raw: Mapped[dict] = mapped_column(JSON)
    updated_at: Mapped[datetime] = _created()


class Permit(Base):
    __tablename__ = "permit"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    permit_no: Mapped[str] = mapped_column(String(64), unique=True)
    serials: Mapped[list[str]] = mapped_column(JSON)
    area: Mapped[dict] = mapped_column(JSON)  # GeoJSON (Multi)Polygon
    valid_from: Mapped[datetime] = mapped_column(UTCDateTime)
    valid_to: Mapped[datetime] = mapped_column(UTCDateTime)
    max_alt_m: Mapped[float | None] = mapped_column(Double)
    operator_name: Mapped[str | None] = mapped_column(String(200))
    raw: Mapped[dict] = mapped_column(JSON)


class AircraftTrack(Base):
    __tablename__ = "aircraft_track"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    icao24: Mapped[str] = mapped_column(String(6), index=True)
    callsign: Mapped[str | None] = mapped_column(String(8))
    at: Mapped[datetime] = mapped_column(UTCDateTime)
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    alt_m: Mapped[float | None] = mapped_column(Double)
    ground_speed_mps: Mapped[float | None] = mapped_column(Double)
    track_deg: Mapped[float | None] = mapped_column(Double)
    on_ground: Mapped[bool] = mapped_column(Boolean, default=False)
    source_id: Mapped[str] = mapped_column(String(64))


class VesselTrack(Base):
    """Maritime picture: AIS position reports and non-cooperative MDA sensor tracks."""

    __tablename__ = "vessel_track"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    # ais: cooperative AIS (identified by MMSI). mda: non-cooperative maritime sensor track (no identity).
    source_kind: Mapped[str] = mapped_column(String(8), default="ais", server_default="ais")
    mmsi: Mapped[str | None] = mapped_column(String(9), index=True)
    track_id: Mapped[str | None] = mapped_column(String(64), index=True)
    role: Mapped[str | None] = mapped_column(String(16))  # mda: mobile_asset | fixed_site | ambiguous
    role_confidence: Mapped[str | None] = mapped_column(String(8))
    imo: Mapped[str | None] = mapped_column(String(10))
    name: Mapped[str | None] = mapped_column(String(64))
    callsign: Mapped[str | None] = mapped_column(String(16))
    ship_type: Mapped[int | None] = mapped_column(SmallInteger)
    flag: Mapped[str | None] = mapped_column(String(3))
    length_m: Mapped[float | None] = mapped_column(Double)
    at: Mapped[datetime] = mapped_column(UTCDateTime)
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    sog_kn: Mapped[float | None] = mapped_column(Double)
    cog_deg: Mapped[float | None] = mapped_column(Double)
    heading_deg: Mapped[float | None] = mapped_column(Double)
    nav_status: Mapped[int | None] = mapped_column(SmallInteger)
    source_id: Mapped[str] = mapped_column(String(64))


class AtreidesBatch(Base):
    """One Atreides MDA sensor export (CSV) as received: by upload, feed push or the import command."""

    __tablename__ = "atreides_batch"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    filename: Mapped[str] = mapped_column(String(255))
    rows: Mapped[int] = mapped_column(Integer)
    accepted: Mapped[int] = mapped_column(Integer)
    dropped: Mapped[int] = mapped_column(Integer)
    tracks: Mapped[int] = mapped_column(Integer)
    first_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    last_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    # Seconds added to every timestamp (demo replays move a historic sample to "now"); 0 = original times.
    shifted_s: Mapped[int] = mapped_column(Integer, default=0)
    received_via: Mapped[str] = mapped_column(String(16))  # cli | upload | feed
    received_by: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = _created()


class AtreidesDetection(Base):
    """Atreides maritime sensor detection: a position classified as mobile asset, fixed site or ambiguous.

    Not AIS: no vessel identity, speed or course. `track_id` is reconstructed from the route summary the
    export repeats on every row (see uavr/atreides.py).
    """

    __tablename__ = "atreides_detection"
    __table_args__ = (Index("ix_atreides_detection_lat_lon", "lat", "lon"),)
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    batch_id: Mapped[int] = mapped_column(ForeignKey("atreides_batch.id", ondelete="CASCADE"), index=True)
    track_id: Mapped[str] = mapped_column(String(64), index=True)
    at: Mapped[datetime] = mapped_column(UTCDateTime, index=True)
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    role: Mapped[str] = mapped_column(String(16))  # combined: mobile_asset | fixed_site | ambiguous
    primary_role: Mapped[str | None] = mapped_column(String(16))
    primary_confidence: Mapped[str | None] = mapped_column(String(8))
    primary_reasoning: Mapped[str | None] = mapped_column(String(255))
    primary_route_points: Mapped[int | None] = mapped_column(Integer)
    primary_route_span_km: Mapped[float | None] = mapped_column(Double)
    source_role: Mapped[str | None] = mapped_column(String(16))
    source_confidence: Mapped[str | None] = mapped_column(String(8))
    source_reasoning: Mapped[str | None] = mapped_column(String(255))
    source_route_points: Mapped[int | None] = mapped_column(Integer)
    source_route_span_km: Mapped[float | None] = mapped_column(Double)
    content_type: Mapped[str | None] = mapped_column(String(16))
    file_len: Mapped[int | None] = mapped_column(Integer)


class TrackAlert(Base):
    """Maritime behaviour alert on one track (Atreides, AIS or simulated): for human review, not a verdict.

    One open alert per (source_id, track_id); new findings update it. `reasons` explain the score; `method`
    says which detector raised it (rules, statistical baseline, or both).
    """

    __tablename__ = "track_alert"
    __table_args__ = (Index("ix_track_alert_track", "source_id", "track_id"),)
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    source_id: Mapped[str] = mapped_column(String(64))  # vessel_track.source_id (atreides, sim, an AIS feed)
    source_kind: Mapped[str] = mapped_column(String(8))  # ais | mda
    track_id: Mapped[str] = mapped_column(String(64))  # mmsi or MDA track id
    kinds: Mapped[list[str]] = mapped_column(
        JSON, default=list
    )  # stop, deviation, cluster, zone_entry, gap, statistical
    method: Mapped[str] = mapped_column(String(8))  # rules | stat | both
    score: Mapped[int] = mapped_column(SmallInteger)  # 0-100 risk score
    rule_score: Mapped[int] = mapped_column(SmallInteger, default=0)
    stat_score: Mapped[float | None] = mapped_column(Double)  # baseline anomaly score (negative log-likelihood)
    confidence: Mapped[float] = mapped_column(Double)  # data quality 0-1 (sensor confidence, sampling, length)
    reasons: Mapped[list[dict]] = mapped_column(JSON, default=list)  # [{code, text, value, threshold, at, lat, lon}]
    uncertainty: Mapped[list[str]] = mapped_column(JSON, default=list)
    status: Mapped[str] = mapped_column(
        String(16), default="open", index=True
    )  # open|acknowledged|false_alarm|dismissed|escalated
    first_at: Mapped[datetime] = mapped_column(UTCDateTime)
    last_at: Mapped[datetime] = mapped_column(UTCDateTime, index=True)
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    zone_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    case_id: Mapped[uuid.UUID | None] = mapped_column(Uuid)
    suppress_until: Mapped[datetime | None] = mapped_column(UTCDateTime)  # false alarm: stay quiet until then
    updated_by: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = _created()
    updated_at: Mapped[datetime] = mapped_column(UTCDateTime)


class TrackAlertEvent(Base):
    """Timeline of a maritime alert: detections, score changes, operator decisions and notes."""

    __tablename__ = "track_alert_event"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    alert_id: Mapped[int] = mapped_column(ForeignKey("track_alert.id", ondelete="CASCADE"), index=True)
    at: Mapped[datetime] = mapped_column(UTCDateTime)
    actor: Mapped[str | None] = mapped_column(String(64))  # username; None = the detector
    action: Mapped[str] = mapped_column(
        String(24)
    )  # detected | updated | acknowledged | false_alarm | dismissed | reopened | escalated | note
    detail: Mapped[dict] = mapped_column(JSON, default=dict)


class AnomalySetting(Base):
    """Operator-adjustable detector thresholds (one row per key; the engine merges them over its defaults)."""

    __tablename__ = "anomaly_setting"
    key: Mapped[str] = mapped_column(String(48), primary_key=True)
    value: Mapped[float] = mapped_column(Double)
    updated_by: Mapped[str | None] = mapped_column(String(64))
    updated_at: Mapped[datetime] = _created()


class AnomalyLabel(Base):
    """Ground truth for simulated tracks: which injected behaviour a track carries (none = normal)."""

    __tablename__ = "anomaly_label"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_id: Mapped[str] = mapped_column(String(64))
    track_id: Mapped[str] = mapped_column(String(64), index=True)
    kind: Mapped[str] = mapped_column(String(16))  # normal | stop | deviation | cluster | zone_entry | gap
    start_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    end_at: Mapped[datetime | None] = mapped_column(UTCDateTime)


class AnomalyEvaluation(Base):
    """One comparison run of the rule-based and statistical detectors against labelled tracks."""

    __tablename__ = "anomaly_evaluation"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[datetime] = _created()
    source_id: Mapped[str] = mapped_column(String(64))
    tracks: Mapped[int] = mapped_column(Integer)
    anomalous: Mapped[int] = mapped_column(Integer)
    results: Mapped[dict] = mapped_column(
        JSON
    )  # {method: {tp, fp, fn, tn, precision, recall, f1, false_alarm_rate, by_kind}}
    settings: Mapped[dict] = mapped_column(JSON)


class VideoFeed(Base):
    """Agency-operated camera (coastal, harbour, city). Frames are sampled for AI detection."""

    __tablename__ = "video_feed"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    owner: Mapped[str | None] = mapped_column(String(200))
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    bearing_deg: Mapped[float | None] = mapped_column(Double)  # optical axis, if fixed
    fov_deg: Mapped[float | None] = mapped_column(Double)
    snapshot_url: Mapped[str | None] = mapped_column(Text)  # JPEG endpoint (preferred for sampling)
    stream_url: Mapped[str | None] = mapped_column(Text)  # HLS / RTSP for dispatcher viewing
    domains: Mapped[list[str]] = mapped_column(JSON, default=lambda: ["aerial", "surface"])
    sample_interval_s: Mapped[int] = mapped_column(Integer, default=120)
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_sampled_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    last_frame_sha256: Mapped[str | None] = mapped_column(String(64))
    last_error: Mapped[str | None] = mapped_column(Text)
    # Optional watch area in image coordinates (0..1 polygon [[x, y], ...]), e.g. a runway or a pier.
    alert_zone: Mapped[list | None] = mapped_column(JSON)


class VideoTrack(Base):
    """A craft followed across sampled frames of one camera: persistent id, path in the image, behaviours."""

    __tablename__ = "video_track"
    __table_args__ = (Index("ix_video_track_feed_status", "feed_id", "status"),)
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    feed_id: Mapped[str] = mapped_column(ForeignKey("video_feed.id"))
    key: Mapped[str] = mapped_column(String(80), unique=True)  # <feed>-T<n>
    status: Mapped[str] = mapped_column(String(8), default="active")  # active | lost
    craft_domain: Mapped[str] = mapped_column(String(16))
    craft_type: Mapped[str | None] = mapped_column(String(32))
    first_at: Mapped[datetime] = mapped_column(UTCDateTime)
    last_at: Mapped[datetime] = mapped_column(UTCDateTime, index=True)
    hits: Mapped[int] = mapped_column(Integer, default=1)
    # [{"t": iso, "box": [x1, y1, x2, y2] (0..1) | null, "x": centre 0..1, "conf": 0..1, "frame": storage key}]
    path: Mapped[list[dict]] = mapped_column(JSON, default=list)
    behaviours: Mapped[list[dict]] = mapped_column(JSON, default=list)  # [{code, text}]


class AiJob(Base):
    """Queue for model calls. Claimed with SKIP LOCKED; `running` rows enforce the provider's
    concurrency budget across every worker."""

    __tablename__ = "ai_job"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    kind: Mapped[str] = mapped_column(String(16))  # evidence | frame
    priority: Mapped[int] = mapped_column(SmallInteger, default=5)  # lower runs first
    observation_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("observation.id"), index=True)
    evidence_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("evidence.id"))
    feed_id: Mapped[str | None] = mapped_column(ForeignKey("video_feed.id"))
    frame_key: Mapped[str | None] = mapped_column(String(255))  # storage key of a sampled frame
    frame_at: Mapped[datetime | None] = mapped_column(UTCDateTime)  # when the frame was captured (replays)
    status: Mapped[str] = mapped_column(String(12), default="queued", index=True)  # queued|running|done|failed
    attempts: Mapped[int] = mapped_column(SmallInteger, default=0)
    not_before: Mapped[datetime] = _created()
    started_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    finished_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    model: Mapped[str | None] = mapped_column(String(96))
    prompt_version: Mapped[str | None] = mapped_column(String(16))
    latency_s: Mapped[float | None] = mapped_column(Double)
    result: Mapped[dict | None] = mapped_column(JSON)
    error: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = _created()


class WeatherObservation(Base):
    __tablename__ = "weather_observation"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    station_id: Mapped[str] = mapped_column(String(32), index=True)
    at: Mapped[datetime] = mapped_column(UTCDateTime, index=True)
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    visibility_m: Mapped[float | None] = mapped_column(Double)
    wind_speed_mps: Mapped[float | None] = mapped_column(Double)
    wind_dir_deg: Mapped[float | None] = mapped_column(Double)
    precip_mm: Mapped[float | None] = mapped_column(Double)
    raw: Mapped[dict] = mapped_column(JSON)


class Sensor(Base):
    __tablename__ = "sensor"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    kind: Mapped[str] = mapped_column(String(16))  # rf | radar | remote_id
    name: Mapped[str] = mapped_column(String(200))
    lat: Mapped[float | None] = mapped_column(Double)
    lon: Mapped[float | None] = mapped_column(Double)
    classification: Mapped[int] = mapped_column(SmallInteger, default=1)
    agency_id: Mapped[int | None] = mapped_column(ForeignKey("agency.id"))
    last_seen: Mapped[datetime | None] = mapped_column(UTCDateTime)


class CctvCamera(Base):
    __tablename__ = "cctv_camera"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    lat: Mapped[float] = mapped_column(Double)
    lon: Mapped[float] = mapped_column(Double)
    stream_url: Mapped[str | None] = mapped_column(Text)
    snapshot_url: Mapped[str | None] = mapped_column(Text)
    owner: Mapped[str | None] = mapped_column(String(200))
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)


class FeedClient(Base):
    """Credential for an external feed (vendor sensor network or partner agency)."""

    __tablename__ = "feed_client"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    sources: Mapped[list[str]] = mapped_column(JSON)  # feed names it may post to
    key_hash: Mapped[bytes] = mapped_column(Hash, unique=True)
    classification: Mapped[int] = mapped_column(SmallInteger, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_used: Mapped[datetime | None] = mapped_column(UTCDateTime)
    created_at: Mapped[datetime] = _created()


# ---------------------------------------------------------------- live updates, audit, outbox


class LiveEvent(Base):
    """Every WebSocket message, numbered by seq so clients can resync after a disconnect.
    API processes poll this table (MySQL has no LISTEN/NOTIFY)."""

    __tablename__ = "live_event"
    seq: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    at: Mapped[datetime] = mapped_column(UTCDateTime, server_default=NOW, index=True)
    kind: Mapped[str] = mapped_column(String(32))
    case_id: Mapped[uuid.UUID | None] = mapped_column(Uuid)
    desk_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    agency_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    redacted_desk_ids: Mapped[list[int]] = mapped_column(JSON, default=list)
    field_user_ids: Mapped[list[str]] = mapped_column(JSON, default=list)
    min_clearance: Mapped[int] = mapped_column(SmallInteger, default=0)
    payload: Mapped[dict] = mapped_column(JSON)
    redacted_payload: Mapped[dict | None] = mapped_column(JSON)


class AuditLog(Base):
    __tablename__ = "audit_log"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    at: Mapped[datetime] = mapped_column(UTCDateTime, server_default=NOW, index=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, index=True)
    username: Mapped[str | None] = mapped_column(String(128))
    action: Mapped[str] = mapped_column(String(48))
    object_type: Mapped[str | None] = mapped_column(String(32))
    object_id: Mapped[str | None] = mapped_column(String(64))
    ip: Mapped[str | None] = mapped_column(String(64))
    details: Mapped[dict] = mapped_column(JSON, default=dict)


class PushOutbox(Base):
    __tablename__ = "push_outbox"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    token_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("informant_token.id"))
    created_at: Mapped[datetime] = _created()
    sent_at: Mapped[datetime | None] = mapped_column(UTCDateTime)
    attempts: Mapped[int] = mapped_column(SmallInteger, default=0)
    error: Mapped[str | None] = mapped_column(Text)


Index("ix_case_state_deadline", Case.state, Case.ack_deadline)
Index("ix_observation_obs_pos", Observation.observer_lat, Observation.observer_lon)
Index("ix_incident_active_pos", Incident.active, Incident.est_lat, Incident.est_lon)
Index("ix_aircraft_track_at_pos", AircraftTrack.at, AircraftTrack.lat, AircraftTrack.lon)
Index("ix_vessel_track_at_pos", VesselTrack.at, VesselTrack.lat, VesselTrack.lon)
Index("ix_weather_pos", WeatherObservation.lat, WeatherObservation.lon)
Index("ix_cctv_pos", CctvCamera.lat, CctvCamera.lon)
Index("ix_ai_job_claim", AiJob.status, AiJob.priority, AiJob.id)
