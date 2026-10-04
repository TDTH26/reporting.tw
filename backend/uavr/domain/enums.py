from enum import IntEnum, StrEnum


class SourceType(StrEnum):
    informant_android = "informant_android"
    informant_web = "informant_web"
    field_officer = "field_officer"
    remote_id = "remote_id"  # fixed or network Remote ID receivers
    rf_sensor = "rf_sensor"
    radar = "radar"
    video_ai = "video_ai"  # AI detection on a sampled frame of an agency video feed
    mda_sensor = "mda_sensor"  # maritime sensor track (e.g. Atreides) escalated from a behaviour alert


class CraftDomain(StrEnum):
    """Where the craft is. Fusion never merges incidents of different known domains."""

    aerial = "aerial"  # UAVs, balloons, other aircraft-like objects
    surface = "surface"  # USVs, small boats, vessels
    subsurface = "subsurface"  # periscopes, masts, unexplained wakes
    shore = "shore"  # craft landed / beached, objects washed ashore
    unknown = "unknown"


# Default sighting range used to project a single bearing line, per domain.
DOMAIN_SIGHTING_RANGE_M = {"aerial": 300.0, "surface": 1500.0, "subsurface": 1000.0, "shore": 300.0, "unknown": 500.0}

SENSOR_SOURCES = {SourceType.rf_sensor, SourceType.radar, SourceType.remote_id}
INFORMANT_SOURCES = {SourceType.informant_android, SourceType.informant_web}

# Base confidence per source before corroboration and abuse scoring.
BASE_CONFIDENCE = {
    SourceType.informant_android: 0.5,
    SourceType.informant_web: 0.25,
    SourceType.field_officer: 0.8,
    SourceType.remote_id: 0.9,
    SourceType.rf_sensor: 0.85,
    SourceType.radar: 0.85,
    SourceType.video_ai: 0.35,
    SourceType.mda_sensor: 0.7,
}


class Severity(IntEnum):
    low = 1
    medium = 2
    critical = 3


class Clearance(IntEnum):
    """Also used as case/zone/sensor classification label."""

    unclassified = 0
    restricted = 1  # sensitive police / infrastructure data, sensor positions
    defense = 2


class CaseState(StrEnum):
    new = "new"
    acknowledged = "acknowledged"
    investigating = "investigating"
    resolved = "resolved"
    closed = "closed"
    merged = "merged"  # terminal: folded into a surviving case


class CaseAction(StrEnum):
    created = "created"
    acknowledged = "acknowledged"
    investigating = "investigating"
    resolved = "resolved"
    closed = "closed"
    rerouted = "rerouted"
    transferred = "transferred"
    merged = "merged"
    merged_from = "merged_from"
    severity_upgraded = "severity_upgraded"
    severity_downgraded = "severity_downgraded"
    assigned = "assigned"
    field_assigned = "field_assigned"
    evidence_requested = "evidence_requested"
    evidence_received = "evidence_received"
    observation_added = "observation_added"
    note = "note"
    redacted_copy_sent = "redacted_copy_sent"
    recommendation = "recommendation"  # operator decision on a suggested response


class Authorization(StrEnum):
    unknown = "unknown"
    likely_authorized = "likely_authorized"
    no_permit = "no_permit"


class PositionSource(StrEnum):
    informant_projected = "informant_projected"
    triangulated = "triangulated"
    remote_id = "remote_id"
    sensor = "sensor"
    field = "field"


class ZoneType(StrEnum):
    jurisdiction = "jurisdiction"  # default routing area (e.g. a county police bureau)
    open = "open"
    yellow = "yellow"
    red = "red"
    airport = "airport"
    military = "military"
    critical_infrastructure = "critical_infrastructure"
    outlying_islands_strict = "outlying_islands_strict"  # Kinmen / Matsu restricted areas
    residential = "residential"
    # Maritime
    territorial_sea = "territorial_sea"  # Coast Guard jurisdiction (12 nm)
    harbor = "harbor"
    restricted_waters = "restricted_waters"  # military / prohibited waters
    coastal_defense = "coastal_defense"  # protected coastline (landing beaches, coastal installations)


class EvidenceKind(StrEnum):
    photo = "photo"
    video = "video"
    audio = "audio"


class EvidenceStatus(StrEnum):
    pending = "pending"
    verified = "verified"
    hash_mismatch = "hash_mismatch"


class TemplateKind(StrEnum):
    outcome = "outcome"
    evidence_request = "evidence_request"


LANGUAGES = ("zh-TW", "en", "vi", "id", "th", "fil", "de", "fr")
DEFENSE_OUTCOME = "handled_by_authority"
