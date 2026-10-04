"""Response recommendations for a case: decision support for the operator, never device control.

Each suggestion says what to do and why (camera, nearest field unit, operator position, registry lookup,
area warning, tower notification, patrol boat). Accepting a field-unit suggestion assigns that officer;
everything else is simulated and only recorded. Re-running keeps decisions and refreshes open suggestions.
"""

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.dialects.mysql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from .db.models import AppUser, Case, CaseRecommendation, CctvCamera, Incident, Zone
from .domain.geo import distance_m
from .geoutil import bbox_deg

CAMERA_RADIUS_M = 3000
FIELD_RADIUS_M = 30_000
CRITICAL_ZONES = {"airport", "military", "critical_infrastructure", "outlying_islands_strict"}
PROTECTED_WATERS = {"restricted_waters", "coastal_defense", "harbor", "military"}


def _km(m: float) -> str:
    return f"{m / 1000:.1f} km" if m >= 1000 else f"{m:.0f} m"


async def _suggestions(session: AsyncSession, case: Case, inc: Incident) -> list[dict]:
    out: list[dict] = []
    lat, lon = inc.est_lat, inc.est_lon
    if lat is None or lon is None:
        return out
    zones = []
    if inc.matched_zone_ids:
        zones = list((await session.execute(select(Zone).where(Zone.id.in_(inc.matched_zone_ids)))).scalars())
    critical = [z for z in zones if z.zone_type in CRITICAL_ZONES]
    aerial = (inc.craft_domain or "aerial") == "aerial"

    def add(kind, target, priority, text, reason, **detail):
        out.append(
            {
                "code": f"{kind}:{target}" if target else kind,
                "kind": kind,
                "priority": priority,
                "text": text,
                "reason": reason,
                "detail": detail,
            }
        )

    if aerial and inc.adsb_nearby:
        add(
            "atc",
            None,
            1,
            "Alert air traffic control: issue a traffic advisory to manned aircraft nearby",
            f"{len(inc.adsb_nearby)} manned aircraft reported by ADS-B near the drone",
        )
    airports = [z for z in critical if z.zone_type == "airport"]
    if aerial and airports:
        add(
            "tower",
            airports[0].code,
            2,
            f"Notify the {airports[0].name} tower through the Aviation Police; consider holding departures (simulated)",
            "The drone is inside an airport no-fly area",
        )

    # Nearest camera that can look at the estimated position.
    dlat, dlon = bbox_deg(lat, CAMERA_RADIUS_M)
    cams = (
        await session.execute(
            select(CctvCamera).where(
                CctvCamera.lat.between(lat - dlat, lat + dlat),
                CctvCamera.lon.between(lon - dlon, lon + dlon),
                CctvCamera.classification <= case.classification + 1,
            )
        )
    ).scalars()
    cams = sorted(((distance_m(lat, lon, c.lat, c.lon), c) for c in cams), key=lambda x: x[0])
    if cams and cams[0][0] <= CAMERA_RADIUS_M:
        d, c = cams[0]
        add(
            "camera",
            c.id,
            3,
            f"Point camera {c.name} at the estimated position and record (simulated)",
            f"Closest camera, {_km(d)} from the estimated position",
            camera_id=c.id,
        )

    # Nearest on-duty field officer with a known position.
    officers = (
        await session.execute(select(AppUser).where(AppUser.active, AppUser.on_duty, AppUser.last_lat.is_not(None)))
    ).scalars()
    near = sorted(
        (distance_m(lat, lon, u.last_lat, u.last_lon), u)
        for u in officers
        if "field_officer" in (u.roles or []) and u.last_lon is not None
    )
    goal_lat, goal_lon = (inc.operator_lat, inc.operator_lon) if inc.operator_lat is not None else (lat, lon)
    if near and near[0][0] <= FIELD_RADIUS_M:
        d, u = near[0]
        where = "the operator position" if inc.operator_lat is not None else "the estimated position"
        add(
            "field",
            str(u.id),
            4,
            f"Send {u.display_name or u.username} to {where}",
            f"Nearest on-duty field unit, {_km(d)} away",
            user_id=str(u.id),
            lat=goal_lat,
            lon=goal_lon,
        )
    elif aerial:
        add(
            "patrol",
            None,
            4,
            "Ask the local police dispatch for the nearest patrol car",
            "No on-duty field unit with a known position within 30 km",
        )

    if aerial and inc.operator_lat is not None:
        d = distance_m(lat, lon, inc.operator_lat, inc.operator_lon)
        add(
            "operator",
            None,
            5,
            "Go to the operator position broadcast by Remote ID",
            f"The pilot is {_km(d)} from the drone; drones are flown within sight",
            lat=inc.operator_lat,
            lon=inc.operator_lon,
        )
    for serial in (inc.remote_id_serials or [])[:2]:
        add(
            "registry",
            serial,
            6,
            f"Look up serial {serial} in the CAA drone registry and call the operator",
            "The drone broadcasts Remote ID",
        )
    if aerial and critical and case.severity >= 2:
        z = critical[0]
        add(
            "warn",
            z.code,
            7,
            f"Issue an area warning around {z.name} (cell broadcast or loudspeaker, simulated)",
            f"Drone inside a {z.zone_type.replace('_', ' ')} zone; people nearby may need to keep clear",
        )

    if not aerial:
        waters = [z for z in zones if z.zone_type in PROTECTED_WATERS]
        add(
            "boat",
            None,
            2,
            "Task the nearest Coast Guard patrol boat to identify the vessel",
            "A surface contact" + (f" inside {waters[0].name}" if waters else " near the coast"),
        )
        add(
            "sensor",
            None,
            5,
            "Request extra maritime sensor coverage of the area (Atreides)",
            "Keeps the track alive if the vessel switches off AIS",
        )

    if not out or case.severity <= 1:
        add(
            "evidence",
            None,
            8,
            "Monitor and ask the informant for a photo or video through the app",
            "Low severity: more evidence before sending anyone",
        )
    return out


async def refresh(session: AsyncSession, case: Case) -> list[CaseRecommendation]:
    """Propose suggestions for the case's current picture; decided ones are kept as they are."""
    inc = await session.get(Incident, case.incident_id)
    if inc is not None and case.state not in ("resolved", "closed"):
        for s in await _suggestions(session, case, inc):
            stmt = insert(CaseRecommendation).values(case_id=case.id, status="proposed", **s)
            await session.execute(
                stmt.on_duplicate_key_update(
                    text=stmt.inserted.text,
                    reason=stmt.inserted.reason,
                    detail=stmt.inserted.detail,
                    priority=stmt.inserted.priority,
                )
            )
        await session.flush()
    rows = (
        await session.execute(
            select(CaseRecommendation)
            .where(CaseRecommendation.case_id == case.id)
            .order_by(CaseRecommendation.priority, CaseRecommendation.id)
        )
    ).scalars()
    return list(rows)


def as_dict(r: CaseRecommendation) -> dict:
    return {
        "id": r.id,
        "code": r.code,
        "kind": r.kind,
        "priority": r.priority,
        "text": r.text,
        "reason": r.reason,
        "detail": r.detail,
        "status": r.status,
        "final_text": r.final_text,
        "note": r.note,
        "decided_by": r.decided_by,
        "decided_at": r.decided_at.astimezone(UTC).isoformat().replace("+00:00", "Z") if r.decided_at else None,
    }


def now() -> datetime:
    return datetime.now(UTC)
