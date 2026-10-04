"""Fusion: Observation -> Incident.

Narrow interface (`fuse`, `recompute`) so this module can move into its own service later.
Concurrency: new incidents are serialised with MySQL named locks (GET_LOCK) on the 3x3 grid cells around the
observation (and on any Remote ID serial); existing incidents are locked with SELECT ... FOR UPDATE.
A surge of hundreds of reports about one craft therefore always lands in a single incident.
Spatial matching uses an indexed bounding-box prefilter in SQL and exact distances in Python.
"""

import json
import uuid
from datetime import datetime, timedelta

from sqlalchemy import func, or_, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from .. import interview
from ..config import get_settings
from ..db.models import (
    AircraftTrack,
    Incident,
    Observation,
    Permit,
    RegistryEntry,
    VesselTrack,
    WeatherObservation,
    Zone,
)
from ..domain.enums import (
    DOMAIN_SIGHTING_RANGE_M,
    INFORMANT_SOURCES,
    SENSOR_SOURCES,
    Authorization,
    PositionSource,
    SourceType,
)
from ..domain.geo import distance_m, neighbourhood_lock_keys
from ..geoutil import bbox_deg, distance_to_geometry_m
from ..security.hashing import keyed_hash
from . import severity as sev
from .triangulate import BearingLine, Fix, project_single, triangulate

MAX_OBS_FOR_RECOMPUTE = 300
ASSUMED_DRONE_ALT_M = 120.0
LOCK_TIMEOUT_S = 60  # a genuine surge queues behind the same grid cell; waiting beats failing


def reference_point(obs: Observation) -> tuple[float, float]:
    """Best single-point guess of where the craft is, for clustering."""
    if obs.drone_lat is not None:
        return obs.drone_lat, obs.drone_lon
    if obs.bearing_deg is not None:
        f = project_single(
            # Elevation only gives range for things in the air.
            BearingLine(
                obs.observer_lat,
                obs.observer_lon,
                obs.bearing_deg,
                obs.elevation_deg if obs.craft_domain == "aerial" else None,
            ),
            obs.altitude_m,
            sighting_range(obs),
        )
        return f.lat, f.lon
    return obs.observer_lat, obs.observer_lon


MARITIME = {"surface", "subsurface", "shore"}


def family(domain: str | None) -> str:
    """Aerial and maritime contacts never fuse; within maritime, a boat seen offshore and later
    beached is the same event."""
    if domain in MARITIME:
        return "maritime"
    return "aerial" if domain == "aerial" else "unknown"


def sighting_range(obs: Observation) -> float:
    est = (obs.raw_payload or {}).get("est_distance_m")
    if est:
        return float(est)
    if obs.craft_domain == "aerial":
        return get_settings().default_sighting_range_m
    return DOMAIN_SIGHTING_RANGE_M.get(obs.craft_domain or "unknown", 500.0)


async def _lock(session: AsyncSession, names: list[str]) -> None:
    """Named locks, acquired in sorted order (no deadlocks); released when the session closes."""
    session.info["named_locks"] = True
    for name in sorted(set(names)):
        got = (await session.execute(text("SELECT GET_LOCK(:n, :t)"), {"n": name, "t": LOCK_TIMEOUT_S})).scalar()
        if got != 1:
            raise TimeoutError(f"could not acquire fusion lock {name}")


def _serial_lock(serial: str) -> str:
    return "uavr:serial:" + keyed_hash("lock", serial).hex()[:32]


def json_has(col, value) -> object:
    """JSON array column contains value."""
    return func.json_contains(col, json.dumps(value))


async def fuse(session: AsyncSession, obs: Observation) -> tuple[Incident, bool]:
    """Attach an observation to an incident (creating one if needed) and recompute it.

    Returns (incident, created). The caller commits; routing is applied by the caller.
    """
    s = get_settings()
    lat, lon = reference_point(obs)
    names = [f"uavr:cell:{k}" for k in neighbourhood_lock_keys(lat, lon)]
    if obs.remote_id_serial:
        names.append(_serial_lock(obs.remote_id_serial))
    await _lock(session, names)

    fam = family(obs.craft_domain)
    # Boats are slow and visible from far away: wider radius, longer window.
    radius = s.cluster_radius_m * (2.5 if fam == "maritime" else 1.0)
    window = s.cluster_window_s * (3 if fam == "maritime" else 1)
    since = obs.observed_at - timedelta(seconds=window)
    if fam == "maritime":
        domains = [*MARITIME, "unknown"]
    elif fam == "aerial":
        domains = ["aerial", "unknown"]
    else:
        domains = None

    incident = None
    if obs.source_id and obs.source_type in SENSOR_SOURCES:
        # Continuity: later updates of the same sensor track stay in that track's incident.
        incident = (
            await session.execute(
                select(Incident)
                .join(Observation, Observation.incident_id == Incident.id)
                .where(
                    Observation.source_id == obs.source_id,
                    Observation.source_type == obs.source_type,
                    Incident.active,
                    Incident.merged_into_id.is_(None),
                    Incident.last_seen >= since,
                )
                .order_by(Observation.observed_at.desc())
                .limit(1)
                .with_for_update(of=Incident)
            )
        ).scalar_one_or_none()

    if incident is None:
        dlat, dlon = bbox_deg(lat, radius)
        near = Incident.est_lat.between(lat - dlat, lat + dlat) & Incident.est_lon.between(lon - dlon, lon + dlon)
        match = or_(near, json_has(Incident.remote_id_serials, obs.remote_id_serial)) if obs.remote_id_serial else near
        q = select(Incident).where(
            Incident.active, Incident.merged_into_id.is_(None), Incident.last_seen >= since, match
        )
        if domains is not None:
            q = q.where(Incident.craft_domain.in_(domains))
        candidates = (await session.execute(q.with_for_update(of=Incident))).scalars().all()
        best = None
        for c in candidates:
            serial_hit = bool(obs.remote_id_serial and obs.remote_id_serial in (c.remote_id_serials or []))
            d = distance_m(lat, lon, c.est_lat, c.est_lon) if c.est_lat is not None else float("inf")
            if not serial_hit and d > radius:
                continue
            rank = (0 if serial_hit else 1, d)
            if best is None or rank < best[0]:
                best = (rank, c)
        incident = best[1] if best else None

    created = incident is None
    if created:
        incident = Incident(
            id=uuid.uuid4(),
            first_seen=obs.observed_at,
            last_seen=obs.observed_at,
            est_lat=lat,
            est_lon=lon,
            classification=obs.classification,
            craft_domain=obs.craft_domain or "aerial",
        )
        session.add(incident)
        await session.flush()
    obs.incident_id = incident.id
    await session.flush()
    await recompute(session, incident)
    return incident, created


async def recompute(session: AsyncSession, incident: Incident) -> None:
    """Re-derive every fused attribute of an incident from its observations."""
    s = get_settings()
    obs_list = list(
        (
            await session.execute(
                select(Observation)
                .where(Observation.incident_id == incident.id)
                .order_by(Observation.observed_at.desc())
                .limit(MAX_OBS_FOR_RECOMPUTE)
            )
        ).scalars()
    )
    if not obs_list:
        return
    obs_list.reverse()  # chronological

    incident.first_seen = min(incident.first_seen, obs_list[0].observed_at)
    incident.last_seen = max(o.observed_at for o in obs_list)
    incident.observation_count = (
        await session.execute(select(func.count()).where(Observation.incident_id == incident.id))
    ).scalar_one()
    incident.remote_id_serials = sorted({o.remote_id_serial for o in obs_list if o.remote_id_serial})
    incident.classification = max([incident.classification] + [o.classification for o in obs_list])
    incident.sensor_confirmed = any(o.source_type in SENSOR_SOURCES for o in obs_list)
    incident.craft_domain, incident.craft_type = _craft(obs_list)
    facts = [interview.evaluate((o.interview or {}).get("answers")) for o in obs_list if o.interview]
    devices = {o.device_hash for o in obs_list if o.source_type in INFORMANT_SOURCES and o.device_hash}
    incident.distinct_informants = len(devices)

    # --- position, in priority order: sensor / Remote ID > triangulation > field > single projection
    fix, source = _position(obs_list, s.default_sighting_range_m)
    if fix:
        incident.est_lat, incident.est_lon = fix.lat, fix.lon
        incident.est_error_m = round(fix.error_m, 1)
        if fix.altitude_m is not None:
            incident.est_altitude_m = round(fix.altitude_m, 1)
        incident.position_source = source
    lat, lon = incident.est_lat, incident.est_lon

    drone_pts = [(o.observed_at, o.drone_lat, o.drone_lon) for o in obs_list if o.drone_lat is not None]
    if len(drone_pts) >= 2:
        drone_pts.sort(key=lambda t: t[0])
        incident.track = [[p[1], p[2]] for p in drone_pts[-200:]]
    ops = [o for o in obs_list if o.operator_lat is not None]
    if ops:
        incident.operator_lat, incident.operator_lon = ops[-1].operator_lat, ops[-1].operator_lon

    alt = incident.est_altitude_m or ASSUMED_DRONE_ALT_M

    # --- zones (bounding-box prefilter in SQL, exact distance in Python)
    radius = min(incident.est_error_m or 0, 500)
    dlat, dlon = bbox_deg(lat, radius)
    zone_rows = (
        (
            await session.execute(
                select(Zone).where(
                    Zone.active,
                    Zone.min_lat <= lat + dlat,
                    Zone.max_lat >= lat - dlat,
                    Zone.min_lon <= lon + dlon,
                    Zone.max_lon >= lon - dlon,
                )
            )
        )
        .scalars()
        .all()
    )
    zones = [
        z
        for z in zone_rows
        if (incident.craft_domain == "unknown" or incident.craft_domain in (z.domains or []))
        and distance_to_geometry_m(z.geometry, lat, lon) <= radius
    ]
    incident.matched_zone_ids = sorted(z.id for z in zones)
    if zones:
        incident.classification = max(incident.classification, *(z.classification for z in zones))

    # --- registry and permits
    incident.authorization = Authorization.unknown.value
    incident.permit_id = None
    incident.registry_serial = None
    if incident.remote_id_serials:
        reg = (
            await session.execute(
                select(RegistryEntry).where(RegistryEntry.serial.in_(incident.remote_id_serials)).limit(1)
            )
        ).scalar_one_or_none()
        if reg:
            incident.registry_serial = reg.serial
        permits = (
            (
                await session.execute(
                    select(Permit).where(
                        func.json_overlaps(Permit.serials, json.dumps(incident.remote_id_serials)),
                        Permit.valid_from <= incident.last_seen,
                        Permit.valid_to >= incident.last_seen,
                        or_(Permit.max_alt_m.is_(None), Permit.max_alt_m >= alt),
                    )
                )
            )
            .scalars()
            .all()
        )
        permit = next((p for p in permits if distance_to_geometry_m(p.area, lat, lon) == 0), None)
        if permit:
            incident.authorization = Authorization.likely_authorized.value
            incident.permit_id = permit.id
        else:
            incident.authorization = Authorization.no_permit.value

    # --- manned traffic (ADS-B)
    t = incident.last_seen
    # Fresh traffic still counts for a craft seen in the last 15 minutes (it is probably still airborne).
    wall = datetime.now(t.tzinfo)
    upper = max(t, wall) if wall - t < timedelta(minutes=15) else t
    dlat, dlon = bbox_deg(lat, s.adsb_proximity_m)
    rows = (
        (
            await session.execute(
                select(AircraftTrack)
                .where(
                    AircraftTrack.at.between(t - timedelta(seconds=90), upper + timedelta(seconds=30)),
                    AircraftTrack.lat.between(lat - dlat, lat + dlat),
                    AircraftTrack.lon.between(lon - dlon, lon + dlon),
                    AircraftTrack.on_ground.is_(False),
                    or_(AircraftTrack.alt_m.is_(None), func.abs(AircraftTrack.alt_m - alt) <= s.adsb_vertical_m),
                )
                .order_by(AircraftTrack.at.desc())
            )
        )
        .scalars()
        .all()
    )
    latest: dict[str, tuple[AircraftTrack, float]] = {}
    for a in rows:  # newest first: keep each aircraft's latest position
        d = distance_m(lat, lon, a.lat, a.lon)
        if a.icao24 not in latest and d <= s.adsb_proximity_m:
            latest[a.icao24] = (a, d)
    incident.adsb_nearby = [
        {"icao24": a.icao24, "callsign": a.callsign, "alt_m": a.alt_m, "distance_m": round(d)}
        for a, d in sorted(latest.values(), key=lambda x: x[1])
    ]

    # --- weather context
    dlat, dlon = bbox_deg(lat, 30000)
    stations = (
        (
            await session.execute(
                select(WeatherObservation).where(
                    WeatherObservation.at >= t - timedelta(minutes=45),
                    WeatherObservation.lat.between(lat - dlat, lat + dlat),
                    WeatherObservation.lon.between(lon - dlon, lon + dlon),
                )
            )
        )
        .scalars()
        .all()
    )
    wx = min(stations, key=lambda w: distance_m(lat, lon, w.lat, w.lon), default=None)
    incident.weather = (
        {
            "station_id": wx.station_id,
            "at": wx.at.isoformat(),
            "visibility_m": wx.visibility_m,
            "wind_speed_mps": wx.wind_speed_mps,
            "wind_dir_deg": wx.wind_dir_deg,
        }
        if wx
        else None
    )

    incident.confidence = _confidence(obs_list, incident.weather)

    incident.vessel_match = await _ais_match(session, incident) if family(incident.craft_domain) == "maritime" else None
    vm = incident.vessel_match or {}
    ai = _merge_ai(obs_list)
    incident.ai_assessment = ai

    informant_only = all(o.source_type in INFORMANT_SOURCES for o in obs_list)
    inp = sev.SeverityInput(
        zone_types={z.zone_type for z in zones},
        authorization=Authorization(incident.authorization),
        sensor_confirmed=incident.sensor_confirmed,
        has_remote_id=bool(incident.remote_id_serials),
        adsb_nearby=bool(incident.adsb_nearby),
        only_web_reports=informant_only and all(o.source_type == SourceType.informant_web for o in obs_list),
        single_report=len(obs_list) == 1,
        hovering=_hovering([(p[0], p[1], p[2]) for p in drone_pts]),
        domain=incident.craft_domain,
        unmanned_surface=incident.craft_type == "usv" or any(f.unmanned_surface for f in facts),
        dark_vessel=bool(vm.get("dark")),
        ais_identified=bool(vm.get("mmsi")),
        shore_landing=any(f.shore_landing for f in facts),
        people_unloading=any("people_unloading" in f.flags for f in facts),
        approaching_shore=any(f.towards_shore and f.near_shore for f in facts),
    )
    result = sev.compute(inp)
    # AI is advisory and may only raise: at most one level above the rule-based result, and Critical
    # only with corroboration (2+ independent informants or a non-informant source) - otherwise one crafted
    # photo could page a Critical desk.
    ai_level = int((ai or {}).get("threat_level", 0))
    if ai_level > result.severity:
        corroborated = incident.distinct_informants >= 2 or not informant_only
        cap = min(int(result.severity) + 1, 3 if corroborated else 2)
        inp.ai_threat = min(ai_level, cap)
        result = sev.compute(inp)
    incident.auto_severity = int(result.severity)
    incident.severity_reasons = result.reasons
    await session.flush()


def _position(obs_list: list[Observation], default_range: float) -> tuple[Fix | None, str | None]:
    now = obs_list[-1].observed_at
    fresh = [o for o in obs_list if (now - o.observed_at) <= timedelta(minutes=5)]
    for kinds, src in (
        ({SourceType.rf_sensor, SourceType.radar, SourceType.mda_sensor}, PositionSource.sensor),
        ({SourceType.remote_id, SourceType.informant_android, SourceType.field_officer}, PositionSource.remote_id),
    ):
        pts = [o for o in fresh if o.drone_lat is not None and o.source_type in kinds]
        if pts:
            p = pts[-1]
            return Fix(
                p.drone_lat, p.drone_lon, 30.0 if src == PositionSource.sensor else 15.0, p.altitude_m, 1
            ), src.value

    # One bearing line per independent observer (latest), weighted by confidence.
    by_observer: dict = {}
    for o in obs_list:
        if o.bearing_deg is None or o.observer_lat is None:
            continue
        by_observer[o.device_hash or o.source_id or o.id] = o
    lines = [
        BearingLine(
            o.observer_lat,
            o.observer_lon,
            o.bearing_deg,
            o.elevation_deg,
            weight=o.confidence * (1 - o.spam_score),
            bearing_sigma_deg=o.bearing_accuracy_deg or 10.0,
        )
        for o in by_observer.values()
    ]
    fix = triangulate(lines)
    if fix:
        return fix, PositionSource.triangulated.value

    field = [o for o in obs_list if o.source_type == SourceType.field_officer and o.observer_lat is not None]
    if lines:
        best = max(lines, key=lambda line_: line_.weight)
        alts = [o.altitude_m for o in obs_list if o.altitude_m is not None]
        return project_single(best, alts[-1] if alts else None, default_range), PositionSource.informant_projected.value
    if field:
        return Fix(field[-1].observer_lat, field[-1].observer_lon, 200.0, None, 1), PositionSource.field.value
    last = obs_list[-1]
    if last.observer_lat is None:
        return None, None
    return Fix(last.observer_lat, last.observer_lon, 500.0, None, 1), PositionSource.informant_projected.value


# Most specific / most concerning type wins when reports disagree.
TYPE_PRIORITY = [
    "submarine",
    "uuv",
    "usv",
    "landed_boat",
    "uav_fixed_wing",
    "uav_multirotor",
    "uav",
    "balloon",
    "small_boat",
    "fishing_vessel",
    "ship",
    "vessel",
    "object_ashore",
    "unknown_subsurface",
]
TRUSTED_TYPE_SOURCES = {SourceType.field_officer, SourceType.rf_sensor, SourceType.radar, SourceType.remote_id}


def _craft(obs_list: list[Observation]) -> tuple[str, str | None]:
    domains = [o.craft_domain for o in obs_list if o.craft_domain and o.craft_domain != "unknown"]
    domain = max(set(domains), key=domains.count) if domains else "unknown"
    trusted = [o.craft_type for o in obs_list if o.craft_type and o.source_type in TRUSTED_TYPE_SOURCES]
    types = trusted or [o.craft_type for o in obs_list if o.craft_type]
    types += [t for o in obs_list if (t := ((o.ai_assessment or {}).get("craft_type"))) and not trusted]
    ranked = sorted(set(types), key=lambda t: TYPE_PRIORITY.index(t) if t in TYPE_PRIORITY else 99)
    return domain, ranked[0] if ranked else None


def _merge_ai(obs_list: list[Observation]) -> dict | None:
    """Highest-threat advisory assessment across observations (raise-only semantics)."""
    items = [o.ai_assessment for o in obs_list if o.ai_assessment]
    if not items:
        return None
    best = max(items, key=lambda a: (a.get("threat_level", 0), a.get("confidence", 0)))
    return {**best, "assessed_observations": len(items)}


async def _ais_match(session: AsyncSession, incident: Incident) -> dict | None:
    """Maritime picture around a surface contact.

    * nearest AIS vessel (MMSI) -> identified;
    * otherwise, with AIS coverage nearby -> `dark` (nothing cooperative transmits there);
    * a non-cooperative MDA track nearby is attached as `mda_track` but never identifies the craft.
    """
    t, lat, lon = incident.last_seen, incident.est_lat, incident.est_lon
    radius = min(max((incident.est_error_m or 300) + 500, 800), 3000)
    dlat, dlon = bbox_deg(lat, 30000)  # coverage radius; matches are filtered tighter below
    rows = (
        (
            await session.execute(
                select(VesselTrack).where(
                    VesselTrack.at.between(t - timedelta(minutes=10), t + timedelta(minutes=2)),
                    VesselTrack.lat.between(lat - dlat, lat + dlat),
                    VesselTrack.lon.between(lon - dlon, lon + dlon),
                )
            )
        )
        .scalars()
        .all()
    )
    scored = sorted(((distance_m(lat, lon, v.lat, v.lon), v) for v in rows), key=lambda x: x[0])

    def nearest(kind: str):
        return next(((d, v) for d, v in scored if v.source_kind == kind and d <= radius), None)

    out: dict = {}
    if hit := nearest("ais"):
        d, v = hit
        out = {
            "mmsi": v.mmsi,
            "name": v.name,
            "callsign": v.callsign,
            "imo": v.imo,
            "ship_type": v.ship_type,
            "flag": v.flag,
            "distance_m": round(d),
            "at": v.at.isoformat(),
            "sog_kn": v.sog_kn,
        }
    else:
        coverage = any(v.source_kind == "ais" for _, v in scored)
        out = {"dark": True, "search_radius_m": radius} if coverage else {"coverage": False}
    if hit := nearest("mda"):
        d, v = hit
        out["mda_track"] = {
            "track_id": v.track_id,
            "role": v.role,
            "role_confidence": v.role_confidence,
            "distance_m": round(d),
            "at": v.at.isoformat(),
        }
    return out


def _confidence(obs_list: list[Observation], weather: dict | None) -> float:
    """Independent sources corroborate: 1 - prod(1 - c_i), one term per source."""
    poor_visibility = bool(weather and (weather.get("visibility_m") or 1e9) < 1000)
    per_source: dict = {}
    for o in obs_list:
        c = o.confidence * (1 - o.spam_score)
        if poor_visibility and o.source_type in INFORMANT_SOURCES:
            c *= 0.6
        key = o.device_hash or o.source_id or o.id
        per_source[key] = max(per_source.get(key, 0.0), c)
    miss = 1.0
    for c in per_source.values():
        miss *= 1 - min(max(c, 0.0), 0.99)
    return 1 - miss


def _hovering(drone_pts: list[tuple[datetime, float, float]]) -> bool:
    if len(drone_pts) < 3:
        return False
    span = (drone_pts[-1][0] - drone_pts[0][0]).total_seconds()
    if span < 60:
        return False
    lats = [p[1] for p in drone_pts]
    lons = [p[2] for p in drone_pts]
    extent = distance_m(min(lats), min(lons), max(lats), max(lons))
    return extent < 60


__all__ = ["fuse", "recompute", "reference_point"]
