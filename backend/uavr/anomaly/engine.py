"""Run the maritime detectors over vessel_track and keep track_alert up to date.

Per source (an AIS feed, Atreides, the simulator) a statistical baseline is trained on the history before the
detection window; tracks inside the window are checked by the rules and the baseline. Findings at or above the
alert score open or update one alert per track. Operators' false alarms stay quiet until suppress_until.
"""

import logging
import uuid
from collections import defaultdict
from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..api.ingest import _fuse_and_route
from ..db.models import AnomalyEvaluation, AnomalyLabel, Observation, TrackAlert, TrackAlertEvent, VesselTrack, Zone
from ..domain.enums import BASE_CONFIDENCE, SourceType
from . import settings as anomaly_settings
from .detect import Baseline, Finding, Point, ProtectedZone, Track, clusters, quality, risk, rules, statistical

log = logging.getLogger("uavr.anomaly")

# Protected waters only: drone zones (outlying-island restrictions, CAA sites) cover fishing grounds and coasts.
PROTECTED = {"restricted_waters", "coastal_defense"}
OPEN = ("open", "acknowledged")
HISTORY_DAYS = 14


def _now() -> datetime:
    return datetime.now(UTC)


async def _zones(session: AsyncSession) -> tuple[list[ProtectedZone], list[ProtectedZone]]:
    """Maritime protected areas (zones that apply to surface craft) and harbours (stops there are normal)."""
    prot, harb = [], []
    for z in (await session.execute(select(Zone).where(Zone.active))).scalars():
        if "surface" not in (z.domains or []):
            continue
        pz = ProtectedZone(z.id, z.name, z.zone_type, z.geometry, z.min_lat, z.min_lon, z.max_lat, z.max_lon)
        if z.zone_type in PROTECTED:
            prot.append(pz)
        elif z.zone_type == "harbor":
            harb.append(pz)
    return prot, harb


async def load_tracks(session: AsyncSession, since: datetime, source_id: str | None = None) -> list[Track]:
    q = select(
        VesselTrack.source_id,
        VesselTrack.source_kind,
        VesselTrack.mmsi,
        VesselTrack.track_id,
        VesselTrack.at,
        VesselTrack.lat,
        VesselTrack.lon,
        VesselTrack.role_confidence,
    ).where(VesselTrack.at >= since)
    if source_id:
        q = q.where(VesselTrack.source_id == source_id)
    groups: dict[tuple, list[Point]] = defaultdict(list)
    kinds: dict[tuple, str] = {}
    for src, kind, mmsi, tid, at, lat, lon, conf in (await session.execute(q)).all():
        key = (src, mmsi or tid)
        if key[1] is None:
            continue
        groups[key].append(Point(at, lat, lon, conf))
        kinds[key] = kind
    out = []
    for (src, key), pts in groups.items():
        pts.sort(key=lambda p: p.at)
        out.append(Track(src, kinds[(src, key)], key, pts))
    return out


def analyse(window: list[Track], history: list[Track], cfg: dict, prot, harb) -> list[Finding]:
    """Rules + baseline for the tracks in the window (one source)."""
    base = Baseline(history or window, cfg["stat_percentile"])
    base_for_rules = base if history else None  # lanes need history, not the tracks being judged
    met = clusters(window, cfg, harb)
    out = []
    for t in window:
        f = rules(t, cfg, prot, harb, base_for_rules)
        if t.key in met:
            f.reasons.append(met[t.key])
        statistical(f, base)
        out.append(f)
    return out


async def run(session: AsyncSession, source_id: str | None = None) -> dict:
    """Detect and upsert alerts. The caller commits."""
    cfg = await anomaly_settings.load(session)
    now = _now()
    window_start = now - timedelta(hours=cfg["lookback_hours"])
    tracks = await load_tracks(session, now - timedelta(days=HISTORY_DAYS), source_id)
    prot, harb = await _zones(session)
    by_source: dict[str, list[Track]] = defaultdict(list)
    for t in tracks:
        by_source[t.source_id].append(t)
    stats = {"tracks": 0, "alerts_new": 0, "alerts_updated": 0}
    for ts in by_source.values():
        window = [t for t in ts if t.points[-1].at >= window_start]
        history = [Track(t.source_id, t.source_kind, t.key, [p for p in t.points if p.at < window_start]) for t in ts]
        history = [t for t in history if len(t.points) >= 2]
        if not window:
            continue
        window = [
            Track(t.source_id, t.source_kind, t.key, [p for p in t.points if p.at >= window_start - timedelta(hours=6)])
            for t in window
        ]
        stats["tracks"] += len(window)
        for f in analyse(window, history, cfg, prot, harb):
            q, notes = quality(f.track)
            score = risk(f, q)
            if not f.reasons or score < cfg["alert_min_score"]:
                continue
            new = await _upsert(session, f, q, notes, score, cfg, now)
            if new is True:
                stats["alerts_new"] += 1
            elif new is False:
                stats["alerts_updated"] += 1
    return stats


async def _upsert(session, f: Finding, q: float, notes: list[str], score: int, cfg: dict, now: datetime) -> bool | None:
    t = f.track
    existing = (
        await session.execute(
            select(TrackAlert)
            .where(TrackAlert.source_id == t.source_id, TrackAlert.track_id == t.key)
            .order_by(TrackAlert.id.desc())
            .limit(1)
        )
    ).scalar_one_or_none()
    quiet = existing and existing.suppress_until and existing.suppress_until > now
    if quiet and existing.status in ("false_alarm", "dismissed"):
        return None
    if existing and existing.status == "escalated":
        return None
    last = t.points[-1]
    reasons = [r.as_dict() for r in f.reasons]
    method = "both" if f.rule_flag and f.stat_flag else ("stat" if f.stat_flag else "rules")
    if existing and existing.status in OPEN:
        changed = set(f.kinds) != set(existing.kinds or []) or abs(score - existing.score) >= 10
        existing.kinds, existing.method, existing.score = f.kinds, method, score
        existing.rule_score, existing.stat_score, existing.confidence = f.rule_score, f.stat_score, q
        existing.reasons, existing.uncertainty, existing.zone_ids = reasons, notes, f.zone_ids
        existing.last_at, existing.lat, existing.lon, existing.updated_at = last.at, last.lat, last.lon, now
        if changed:
            session.add(
                TrackAlertEvent(
                    alert_id=existing.id, at=now, action="updated", detail={"score": score, "kinds": f.kinds}
                )
            )
            return False
        return None
    a = TrackAlert(
        source_id=t.source_id,
        source_kind=t.source_kind,
        track_id=t.key,
        kinds=f.kinds,
        method=method,
        score=score,
        rule_score=f.rule_score,
        stat_score=f.stat_score,
        confidence=q,
        reasons=reasons,
        uncertainty=notes,
        status="open",
        first_at=t.points[0].at,
        last_at=last.at,
        lat=last.lat,
        lon=last.lon,
        zone_ids=f.zone_ids,
        updated_at=now,
    )
    session.add(a)
    await session.flush()
    session.add(
        TrackAlertEvent(
            alert_id=a.id, at=now, action="detected", detail={"score": score, "kinds": f.kinds, "method": method}
        )
    )
    return True


async def track_points(session: AsyncSession, source_id: str, key: str, hours: float = 72) -> list[VesselTrack]:
    since = _now() - timedelta(hours=hours)
    q = select(VesselTrack).where(VesselTrack.source_id == source_id, VesselTrack.at >= since)
    q = q.where((VesselTrack.mmsi == key) | (VesselTrack.track_id == key)).order_by(VesselTrack.at)
    return list((await session.execute(q)).scalars())


async def escalate(session: AsyncSession, a: TrackAlert, actor: str) -> uuid.UUID | None:
    """Turn an alert into an incident/case through normal fusion and routing."""
    pts = await track_points(session, a.source_id, a.track_id)
    obs = Observation(
        id=uuid.uuid4(),
        source_type=SourceType.mda_sensor.value,
        source_id=f"maritime-alert:{a.source_id}:{a.track_id}",
        observed_at=a.last_at,
        drone_lat=a.lat,
        drone_lon=a.lon,
        confidence=BASE_CONFIDENCE[SourceType.mda_sensor] * a.confidence,
        classification=1,
        craft_domain="surface",
        craft_type="vessel",
        description=f"Maritime alert #{a.id} (risk {a.score}): " + "; ".join(r["text"] for r in a.reasons)[:900],
        raw_payload={"feed": "maritime-alert", "alert_id": a.id, "kinds": a.kinds, "escalated_by": actor},
        schema_version="uavr.maritime-alert/1",
        fidelity="high",
    )
    if len(pts) >= 2:
        obs.track = [[p.lat, p.lon, None] for p in pts[-50:]]
    await _fuse_and_route(session, obs)
    await session.flush()
    from ..db.models import Case

    case = (await session.execute(select(Case).where(Case.incident_id == obs.incident_id))).scalar_one_or_none()
    return case.id if case else None


# ------------------------------------------------------------------ rules vs statistics on labelled tracks


def _metrics(flags: dict[str, bool], truth: dict[str, str]) -> dict:
    tp = sum(1 for k, f in flags.items() if f and truth[k] != "normal")
    fp = sum(1 for k, f in flags.items() if f and truth[k] == "normal")
    fn = sum(1 for k, f in flags.items() if not f and truth[k] != "normal")
    tn = sum(1 for k, f in flags.items() if not f and truth[k] == "normal")
    prec = tp / (tp + fp) if tp + fp else 0.0
    rec = tp / (tp + fn) if tp + fn else 0.0
    by_kind: dict[str, dict] = {}
    for kind in sorted({v for v in truth.values() if v != "normal"}):
        keys = [k for k, v in truth.items() if v == kind]
        by_kind[kind] = {"tracks": len(keys), "found": sum(1 for k in keys if flags.get(k))}
    return {
        "tp": tp,
        "fp": fp,
        "fn": fn,
        "tn": tn,
        "precision": round(prec, 3),
        "recall": round(rec, 3),
        "f1": round(2 * prec * rec / (prec + rec), 3) if prec + rec else 0.0,
        "false_alarms_per_100_normal": round(100 * fp / (fp + tn), 1) if fp + tn else 0.0,
        "by_kind": by_kind,
    }


async def evaluate(session: AsyncSession, source_id: str = "sim") -> AnomalyEvaluation | None:
    """Compare rules, the statistical baseline and the combined alert score on labelled tracks."""
    labels = {
        (r.track_id): r.kind
        for r in (await session.execute(select(AnomalyLabel).where(AnomalyLabel.source_id == source_id))).scalars()
    }
    if not labels:
        return None
    cfg = await anomaly_settings.load(session)
    now = _now()
    window_start = now - timedelta(hours=cfg["lookback_hours"])
    tracks = await load_tracks(session, now - timedelta(days=HISTORY_DAYS), source_id)
    prot, harb = await _zones(session)
    window = [
        Track(t.source_id, t.source_kind, t.key, [p for p in t.points if p.at >= window_start - timedelta(hours=6)])
        for t in tracks
        if t.points[-1].at >= window_start and t.key in labels
    ]
    history = [Track(t.source_id, t.source_kind, t.key, [p for p in t.points if p.at < window_start]) for t in tracks]
    history = [t for t in history if len(t.points) >= 2]
    findings = analyse(window, history, cfg, prot, harb)
    truth = {f.track.key: labels[f.track.key] for f in findings}
    res = {
        "rules": _metrics({f.track.key: f.rule_flag for f in findings}, truth),
        "statistical": _metrics({f.track.key: f.stat_flag for f in findings}, truth),
        "combined": _metrics(
            {f.track.key: risk(f, quality(f.track)[0]) >= cfg["alert_min_score"] for f in findings}, truth
        ),
    }
    ev = AnomalyEvaluation(
        source_id=source_id,
        tracks=len(truth),
        anomalous=sum(1 for v in truth.values() if v != "normal"),
        results=res,
        settings=cfg,
    )
    session.add(ev)
    await session.flush()
    await session.refresh(ev)
    return ev


async def clear_source(session: AsyncSession, source_id: str) -> None:
    await session.execute(delete(VesselTrack).where(VesselTrack.source_id == source_id))
    await session.execute(delete(AnomalyLabel).where(AnomalyLabel.source_id == source_id))
    await session.execute(delete(TrackAlert).where(TrackAlert.source_id == source_id))
