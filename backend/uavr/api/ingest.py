"""Ingestion API: one authenticated endpoint per external feed, validated against the JSON schema.

Vendors (sensor networks) must deliver in the platform schema. Partner feeds (CAA, ADS-B, weather)
may be translated by a small adapter owned by either side before posting here.
"""

import hmac
import json
import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Body, Depends, Header, HTTPException, Path
from sqlalchemy import func, select
from sqlalchemy.dialects.mysql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db.models import (
    AircraftTrack,
    CctvCamera,
    FeedClient,
    Incident,
    Observation,
    Permit,
    RegistryEntry,
    Sensor,
    VesselTrack,
    VideoFeed,
    WeatherObservation,
)
from ..db.session import get_session
from ..domain.enums import BASE_CONFIDENCE, SourceType
from ..domain.geo import distance_m
from ..feeds.validate import FEEDS, errors
from ..fusion.engine import fuse, recompute
from ..geoutil import bbox_deg, normalize_multipolygon
from ..routing.router import apply_incident_update
from ..security.hashing import keyed_hash, new_secret

router = APIRouter(prefix="/v1/ingest", tags=["ingestion"])

TRACK_MIN_INTERVAL = timedelta(seconds=5)


def mint_feed_key() -> tuple[str, bytes]:
    key = "uavr_feed_" + new_secret()
    return key, keyed_hash("feed", key)


async def feed_client(
    feed: str = Path(..., description="Feed name"),
    x_feed_key: str = Header(..., alias="X-Feed-Key"),
    session: AsyncSession = Depends(get_session),
) -> FeedClient:
    h = keyed_hash("feed", x_feed_key)
    fc = (await session.execute(select(FeedClient).where(FeedClient.key_hash == h))).scalar_one_or_none()
    if fc is None or not fc.active or not hmac.compare_digest(fc.key_hash, h):
        raise HTTPException(401, "unknown feed key")
    if feed not in fc.sources:
        raise HTTPException(403, f"this key may not post to {feed}")
    fc.last_used = datetime.now(UTC)
    return fc


def _t(s: str) -> datetime:
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


@router.post("/{feed}")
async def ingest(
    feed: str = Path(..., enum=list(FEEDS)),
    payload: dict = Body(...),
    fc: FeedClient = Depends(feed_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    if feed not in FEEDS:
        raise HTTPException(404, "unknown feed")
    errs = errors(feed, payload)
    if errs:
        raise HTTPException(422, {"message": "payload does not conform to the feed schema", "errors": errs})
    handler = HANDLERS[feed]
    result = await handler(session, payload, fc)
    await session.commit()
    return {"accepted": True, **result}


async def _fuse_and_route(session: AsyncSession, obs: Observation) -> None:
    session.add(obs)
    await session.flush()
    incident, created = await fuse(session, obs)
    await apply_incident_update(session, incident, created)


async def _incidents_near(
    session: AsyncSession,
    pts: list[tuple[float, float]],
    radius_m: float,
    *,
    minutes: int,
    domains: tuple[str, ...] | None = None,
) -> list[Incident]:
    """Active incidents within radius_m of any point (bounding box in SQL, exact distance in Python)."""
    if not pts:
        return []
    lats = [p[0] for p in pts]
    lons = [p[1] for p in pts]
    dlat, dlon = bbox_deg(max(abs(x) for x in lats), radius_m)
    q = select(Incident).where(
        Incident.active,
        Incident.merged_into_id.is_(None),
        Incident.last_seen >= datetime.now(UTC) - timedelta(minutes=minutes),
        Incident.est_lat.between(min(lats) - dlat, max(lats) + dlat),
        Incident.est_lon.between(min(lons) - dlon, max(lons) + dlon),
    )
    if domains:
        q = q.where(Incident.craft_domain.in_(domains))
    rows = (await session.execute(q.with_for_update(of=Incident, skip_locked=True))).scalars().all()
    return [i for i in rows if any(distance_m(i.est_lat, i.est_lon, a, b) <= radius_m for a, b in pts)]


async def _sensor_track(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    n = 0
    for tr in p["tracks"]:
        sensor_id = tr["sensor_id"]
        kind = SourceType.radar if tr["sensor_kind"] == "radar" else SourceType.rf_sensor
        sp = tr.get("sensor_position")
        await session.execute(
            insert(Sensor)
            .values(
                id=sensor_id,
                kind=tr["sensor_kind"],
                name=sensor_id,
                lat=sp["lat"] if sp else None,
                lon=sp["lon"] if sp else None,
                classification=max(fc.classification, 1),
                last_seen=datetime.now(UTC),
            )
            .on_duplicate_key_update(last_seen=datetime.now(UTC))
        )
        pts = sorted(tr["points"], key=lambda x: x["t"])
        last = pts[-1]
        source_id = f"{p['source_id']}:{sensor_id}:{tr['track_id']}"
        prev = (
            await session.execute(
                select(Observation.observed_at)
                .where(Observation.source_id == source_id)
                .order_by(Observation.observed_at.desc())
                .limit(1)
            )
        ).scalar_one_or_none()
        if prev and _t(last["t"]) - prev < TRACK_MIN_INTERVAL and tr.get("status") != "ended":
            continue  # throttle: fusion does not need every radar sweep
        cls = tr.get("classification") or {}
        if cls.get("target_type") == "bird":
            continue
        domain = cls.get("target_domain", "aerial")
        craft_type = {
            "multirotor": "uav_multirotor",
            "fixed_wing": "uav_fixed_wing",
            "vtol": "uav",
            "usv": "usv",
            "small_boat": "small_boat",
            "vessel": "vessel",
        }.get(cls.get("target_type", ""))
        rf = tr.get("rf") or {}
        obs = Observation(
            id=uuid.uuid4(),
            source_type=kind.value,
            source_id=source_id,
            observed_at=_t(last["t"]),
            observer_lat=sp["lat"] if sp else None,
            observer_lon=sp["lon"] if sp else None,
            drone_lat=last["lat"],
            drone_lon=last["lon"],
            altitude_m=last.get("alt_m"),
            altitude_source=f"sensor_{last.get('alt_ref', 'agl')}",
            remote_id_serial=rf.get("serial"),
            operator_lat=rf["pilot_position"]["lat"] if rf.get("pilot_position") else None,
            operator_lon=rf["pilot_position"]["lon"] if rf.get("pilot_position") else None,
            confidence=BASE_CONFIDENCE[kind] * float(cls.get("confidence", 1.0)),
            classification=max(fc.classification, 1),
            craft_domain=domain,
            craft_type=craft_type,
            raw_payload={"feed": "sensor-track", "source_id": p["source_id"], "track": tr},
            schema_version="uavr.feed.sensor-track/1",
            fidelity="high",
        )
        if len(pts) >= 2:
            obs.track = [[x["lat"], x["lon"], x.get("alt_m")] for x in pts]
        await _fuse_and_route(session, obs)
        n += 1
    return {"observations": n}


async def _remote_id(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    latest: dict[str, dict] = {}
    for m in p["messages"]:
        if m["uas_id"] not in latest or m["t"] > latest[m["uas_id"]]["t"]:
            latest[m["uas_id"]] = m
    n = 0
    for uas_id, m in latest.items():
        if m.get("lat") is None:
            continue
        obs = Observation(
            id=uuid.uuid4(),
            source_type=SourceType.remote_id.value,
            source_id=f"{p['source_id']}:{m['receiver_id']}:{uas_id}",
            observed_at=_t(m["t"]),
            drone_lat=m["lat"],
            drone_lon=m["lon"],
            altitude_m=m.get("height_m", m.get("alt_geo_m")),
            altitude_source="remote_id",
            remote_id_serial=uas_id,
            remote_id={
                "serial": uas_id,
                "id_type": m.get("id_type"),
                "ua_type": m.get("ua_type"),
                "operator_id": m.get("operator_id"),
                "transport": m.get("transport"),
            },
            operator_lat=m.get("operator_lat"),
            operator_lon=m.get("operator_lon") if m.get("operator_lat") is not None else None,
            confidence=BASE_CONFIDENCE[SourceType.remote_id],
            classification=fc.classification,
            raw_payload={"feed": "remote-id", "source_id": p["source_id"], "message": m},
            schema_version="uavr.feed.remote-id/1",
            fidelity="high",
        )
        await _fuse_and_route(session, obs)
        n += 1
    return {"observations": n}


async def _adsb(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    rows = []
    for st in p["states"]:
        rows.append(
            AircraftTrack(
                icao24=st["icao24"],
                callsign=(st.get("callsign") or "").strip() or None,
                at=_t(st["t"]),
                lat=st["lat"],
                lon=st["lon"],
                alt_m=st.get("alt_geo_m", st.get("alt_baro_m")),
                ground_speed_mps=st.get("ground_speed_mps"),
                track_deg=st.get("track_deg"),
                on_ground=st.get("on_ground", False),
                source_id=p["source_id"],
            )
        )
    session.add_all(rows)
    await session.flush()
    # Re-evaluate active incidents near any reported aircraft (manned traffic escalates to Critical).
    pts = [(st["lat"], st["lon"]) for st in p["states"] if not st.get("on_ground")]
    escalated = 0
    for inc in await _incidents_near(session, pts, get_settings().adsb_proximity_m, minutes=15):
        before = inc.auto_severity
        await recompute(session, inc)
        await apply_incident_update(session, inc, created=False)
        escalated += inc.auto_severity > before
    return {"states": len(rows), "incidents_escalated": escalated}


async def _ais(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    rows = [
        VesselTrack(
            source_kind=v.get("source_kind", "ais" if v.get("mmsi") else "mda"),
            mmsi=v.get("mmsi"),
            track_id=v.get("track_id"),
            role=v.get("role"),
            role_confidence=v.get("role_confidence"),
            imo=v.get("imo"),
            name=(v.get("name") or "").strip() or None,
            callsign=v.get("callsign"),
            ship_type=v.get("ship_type"),
            flag=v.get("flag"),
            length_m=v.get("length_m"),
            at=_t(v["t"]),
            lat=v["lat"],
            lon=v["lon"],
            sog_kn=v.get("sog_kn"),
            cog_deg=v.get("cog_deg"),
            heading_deg=v.get("heading_deg"),
            nav_status=v.get("nav_status"),
            source_id=p["source_id"],
        )
        for v in p["vessels"]
    ]
    session.add_all(rows)
    await session.flush()
    # A transmitting vessel next to a "dark" contact changes its assessment: re-check nearby maritime incidents.
    pts = [(v["lat"], v["lon"]) for v in p["vessels"]]
    incidents = await _incidents_near(session, pts, 5000, minutes=30, domains=("surface", "subsurface", "shore"))
    for inc in incidents:
        await recompute(session, inc)
        await apply_incident_update(session, inc, created=False)
    return {"vessels": len(rows), "incidents_rechecked": len(incidents)}


async def _video_feed(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    for f in p["feeds"]:
        values = dict(
            id=f["feed_id"],
            name=f["name"],
            owner=f.get("owner"),
            lat=f["lat"],
            lon=f["lon"],
            bearing_deg=f.get("bearing_deg"),
            fov_deg=f.get("fov_deg"),
            snapshot_url=f.get("snapshot_url"),
            stream_url=f.get("stream_url"),
            domains=f.get("domains", ["aerial", "surface"]),
            sample_interval_s=f.get("sample_interval_s", 120),
            classification=max(f.get("classification", 0), fc.classification),
            active=f.get("active", True),
        )
        await session.execute(
            insert(VideoFeed).values(**values).on_duplicate_key_update({k: v for k, v in values.items() if k != "id"})
        )
    return {"feeds": len(p["feeds"])}


async def _weather(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    session.add_all(
        WeatherObservation(
            station_id=o["station_id"],
            at=_t(o["t"]),
            lat=o["lat"],
            lon=o["lon"],
            visibility_m=o.get("visibility_m"),
            wind_speed_mps=o.get("wind_speed_mps"),
            wind_dir_deg=o.get("wind_dir_deg"),
            precip_mm=o.get("precip_mm"),
            raw=o,
        )
        for o in p["observations"]
    )
    return {"observations": len(p["observations"])}


async def _registry(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    for r in p["records"]:
        owner = r.get("owner") or {}
        values = dict(
            serial=r["serial"],
            registration_no=r.get("registration_no"),
            owner_name=owner.get("name"),
            owner_ref=owner.get("owner_ref"),
            model=r.get("model"),
            manufacturer=r.get("manufacturer"),
            mtow_g=r.get("mtow_g"),
            status=r["status"],
            raw=r,
            updated_at=datetime.now(UTC),
        )
        await session.execute(
            insert(RegistryEntry)
            .values(**values)
            .on_duplicate_key_update({k: v for k, v in values.items() if k != "serial"})
        )
    return {"records": len(p["records"])}


async def _permit(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    serials: set[str] = set()
    for r in p["permits"]:
        valid_to = _t(r["valid_to"])
        if r.get("status") == "revoked":
            valid_to = min(valid_to, datetime.now(UTC))
        values = dict(
            permit_no=r["permit_no"],
            serials=r["serials"],
            area=normalize_multipolygon(r["area"]),
            valid_from=_t(r["valid_from"]),
            valid_to=valid_to,
            max_alt_m=r.get("max_alt_m"),
            operator_name=r.get("operator_name"),
            raw=r,
        )
        await session.execute(
            insert(Permit)
            .values(**values)
            .on_duplicate_key_update({k: v for k, v in values.items() if k != "permit_no"})
        )
        serials |= set(r["serials"])
    # Live incidents flying these serials may now be (un)authorised.
    incidents = (
        (
            await session.execute(
                select(Incident)
                .where(Incident.active, func.json_overlaps(Incident.remote_id_serials, json.dumps(sorted(serials))))
                .with_for_update(of=Incident, skip_locked=True)
            )
        )
        .scalars()
        .all()
    )
    for inc in incidents:
        await recompute(session, inc)
        await apply_incident_update(session, inc, created=False)
    return {"permits": len(p["permits"]), "incidents_rechecked": len(incidents)}


async def _cctv(session: AsyncSession, p: dict, fc: FeedClient) -> dict:
    for c in p["cameras"]:
        values = dict(
            id=c["camera_id"],
            name=c["name"],
            lat=c["lat"],
            lon=c["lon"],
            stream_url=c.get("stream_url"),
            snapshot_url=c.get("snapshot_url"),
            owner=c.get("owner"),
            classification=max(c.get("classification", 0), fc.classification),
        )
        await session.execute(
            insert(CctvCamera).values(**values).on_duplicate_key_update({k: v for k, v in values.items() if k != "id"})
        )
    return {"cameras": len(p["cameras"])}


HANDLERS = {
    "sensor-track": _sensor_track,
    "remote-id": _remote_id,
    "adsb": _adsb,
    "weather": _weather,
    "registry": _registry,
    "permit": _permit,
    "cctv": _cctv,
    "ais": _ais,
    "video-feed": _video_feed,
}
