"""Serializers for staff-facing case data, with redaction applied per viewer."""

from .db.models import Case, Incident
from .geoutil import latlon, line_geojson


def case_summary(case: Case, incident: Incident | None = None) -> dict:
    inc = incident or case.incident
    return {
        "id": str(case.id),
        "case_number": case.case_number,
        "state": case.state,
        "severity": case.severity,
        "classification": case.classification,
        "agency_id": case.agency_id,
        "desk_id": case.desk_id,
        "assignee_id": str(case.assignee_id) if case.assignee_id else None,
        "ack_deadline": case.ack_deadline.isoformat() if case.ack_deadline else None,
        "created_at": case.created_at.isoformat() if case.created_at else None,
        "updated_at": case.updated_at.isoformat() if case.updated_at else None,
        "position": latlon(inc.est_lat, inc.est_lon) if inc else None,
        "position_source": inc.position_source if inc else None,
        "est_error_m": inc.est_error_m if inc else None,
        "est_altitude_m": inc.est_altitude_m if inc else None,
        "first_seen": inc.first_seen.isoformat() if inc else None,
        "last_seen": inc.last_seen.isoformat() if inc else None,
        "observation_count": inc.observation_count if inc else 0,
        "distinct_informants": inc.distinct_informants if inc else 0,
        "confidence": round(inc.confidence, 3) if inc else 0,
        "authorization": inc.authorization if inc else "unknown",
        "severity_reasons": inc.severity_reasons if inc else [],
        "sensor_confirmed": inc.sensor_confirmed if inc else False,
        "remote_id_serials": inc.remote_id_serials if inc else [],
        "track": line_geojson(inc.track) if inc else None,
        "craft_domain": inc.craft_domain if inc else "aerial",
        "craft_type": inc.craft_type if inc else None,
        "ai_assessment": inc.ai_assessment if inc else None,
        "vessel_match": inc.vessel_match if inc else None,
        "redacted": False,
    }


def redacted_summary(case: Case, incident: Incident | None = None) -> dict:
    """What an uncleared desk sees of a classified case: location, time, severity."""
    inc = incident or case.incident
    return {
        "id": str(case.id),
        "case_number": case.case_number,
        "state": case.state,
        "severity": case.severity,
        "classification": case.classification,
        "agency_id": case.agency_id,
        "desk_id": case.desk_id,
        "created_at": case.created_at.isoformat() if case.created_at else None,
        "position": latlon(inc.est_lat, inc.est_lon) if inc else None,
        "first_seen": inc.first_seen.isoformat() if inc else None,
        "last_seen": inc.last_seen.isoformat() if inc else None,
        "craft_domain": inc.craft_domain if inc else "aerial",
        "redacted": True,
    }
