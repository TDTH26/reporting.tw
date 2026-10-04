"""Maritime behaviour detectors: explainable rules and a statistical baseline, on plain track points.

Pure functions (no database) so the same code runs live, in tests and in the rules-vs-statistics evaluation.
"""

import math
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime

import numpy as np

from ..domain.geo import distance_m
from ..geoutil import distance_to_geometry_m

KN = 1.943844  # m/s -> knots
CELL_DEG = 0.1  # baseline grid (~11 km)
SPEED_BINS = (1.0, 4.0, 8.0, 12.0, 16.0)  # knots: 6 bins
HEADING_BINS = 8
ALPHA = 0.5  # Dirichlet smoothing for the baseline
CELL_WEIGHT = 0.5  # how much an unusual area counts against unusual motion in that area

WEIGHTS = {"zone_entry": 45, "gap": 35, "cluster": 25, "stop": 25, "deviation": 20, "approach": 15}
STAT_POINTS = 25


@dataclass
class Point:
    at: datetime
    lat: float
    lon: float
    confidence: str | None = None  # MDA role confidence (high/low)


@dataclass
class Track:
    source_id: str
    source_kind: str  # ais | mda
    key: str  # mmsi or MDA track id
    points: list[Point]

    def segments(self):
        """(a, b, dt_s, dist_m, speed_kn, heading_deg) for consecutive points."""
        out = []
        for a, b in zip(self.points, self.points[1:], strict=False):
            dt = (b.at - a.at).total_seconds()
            d = distance_m(a.lat, a.lon, b.lat, b.lon)
            sp = d / dt * KN if dt > 0 else 0.0
            out.append((a, b, dt, d, sp, heading(a.lat, a.lon, b.lat, b.lon)))
        return out


@dataclass
class Reason:
    code: str
    text: str
    value: float | None = None
    threshold: float | None = None
    at: datetime | None = None
    lat: float | None = None
    lon: float | None = None

    def as_dict(self) -> dict:
        return {
            "code": self.code,
            "text": self.text,
            "value": None if self.value is None else round(self.value, 2),
            "threshold": self.threshold,
            "at": self.at.isoformat().replace("+00:00", "Z") if self.at else None,
            "lat": self.lat,
            "lon": self.lon,
        }


@dataclass
class Finding:
    track: Track
    reasons: list[Reason] = field(default_factory=list)
    zone_ids: list[int] = field(default_factory=list)
    stat_score: float | None = None
    stat_threshold: float | None = None
    stat_flag: bool = False

    @property
    def kinds(self) -> list[str]:
        ks = sorted({r.code for r in self.reasons if r.code in WEIGHTS})
        return ks + (["statistical"] if self.stat_flag else [])

    @property
    def rule_score(self) -> int:
        return min(100, sum(WEIGHTS[k] for k in {r.code for r in self.reasons if r.code in WEIGHTS}))

    @property
    def rule_flag(self) -> bool:
        return self.rule_score > 0


def heading(lat1, lon1, lat2, lon2) -> float:
    y = math.sin(math.radians(lon2 - lon1)) * math.cos(math.radians(lat2))
    x = math.cos(math.radians(lat1)) * math.sin(math.radians(lat2)) - math.sin(math.radians(lat1)) * math.cos(
        math.radians(lat2)
    ) * math.cos(math.radians(lon2 - lon1))
    return (math.degrees(math.atan2(y, x)) + 360) % 360


def cell(lat: float, lon: float) -> tuple[int, int]:
    return (math.floor(lat / CELL_DEG), math.floor(lon / CELL_DEG))


def motion_bin(speed_kn: float, heading_deg: float) -> int:
    s = sum(speed_kn >= b for b in SPEED_BINS)
    h = 0 if speed_kn < SPEED_BINS[0] else int(((heading_deg + 22.5) % 360) // 45)
    return s * HEADING_BINS + h


N_BINS = (len(SPEED_BINS) + 1) * HEADING_BINS
COMPASS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


def describe_bin(b: int) -> str:
    s, h = divmod(b, HEADING_BINS)
    lo = 0 if s == 0 else SPEED_BINS[s - 1]
    hi = SPEED_BINS[s] if s < len(SPEED_BINS) else None
    speed = f"under {SPEED_BINS[0]:g} kn" if s == 0 else (f"{lo:g}-{hi:g} kn" if hi else f"over {lo:g} kn")
    return speed if s == 0 else f"{speed} heading {COMPASS[h]}"


# ------------------------------------------------------------------ statistical baseline


class Baseline:
    """How traffic normally moves in each grid cell: counts of (speed, heading) bins and distinct tracks.

    Point score = -w·log P(cell) - log P(motion | cell), Dirichlet-smoothed. A track's score is the mean of its
    two least likely points; the alert threshold is a percentile of the training tracks' scores.
    """

    def __init__(self, tracks: list[Track], percentile: float):
        self.bins: dict[tuple, np.ndarray] = defaultdict(lambda: np.zeros(N_BINS))
        self.tracks_in: dict[tuple, set] = defaultdict(set)
        for t in tracks:
            for a, _b, dt, _d, sp, hd in t.segments():
                if dt <= 0:
                    continue
                c = cell(a.lat, a.lon)
                self.bins[c][motion_bin(sp, hd)] += 1
                self.tracks_in[c].add(t.key)
        self.total = float(sum(v.sum() for v in self.bins.values()))
        self.n_cells = len(self.bins)
        scores = [s for s in (self.track_score(t)[0] for t in tracks) if s is not None]
        self.threshold = float(np.percentile(scores, percentile)) if len(scores) >= 20 else None

    @property
    def ready(self) -> bool:
        return self.threshold is not None

    def point_score(self, lat: float, lon: float, b: int) -> tuple[float, float, float]:
        """(score, P(cell share), P(motion | cell))."""
        counts = self.bins.get(cell(lat, lon))
        n_cell = float(counts.sum()) if counts is not None else 0.0
        p_cell = (n_cell + 1) / (self.total + self.n_cells + 1)
        n_bin = float(counts[b]) if counts is not None else 0.0
        p_bin = (n_bin + ALPHA) / (n_cell + ALPHA * N_BINS)
        return -CELL_WEIGHT * math.log(p_cell) - math.log(p_bin), p_cell, p_bin

    def track_score(self, t: Track) -> tuple[float | None, dict | None]:
        pts = []
        for a, _b, dt, _d, sp, hd in t.segments():
            if dt <= 0:
                continue
            b = motion_bin(sp, hd)
            sc, p_cell, p_bin = self.point_score(a.lat, a.lon, b)
            pts.append((sc, a, b, p_cell, p_bin))
        if not pts:
            return None, None
        pts.sort(key=lambda x: -x[0])
        top = pts[:2]
        worst = top[0]
        return sum(x[0] for x in top) / len(top), {
            "at": worst[1].at,
            "lat": worst[1].lat,
            "lon": worst[1].lon,
            "motion": describe_bin(worst[2]),
            "p_bin": worst[4],
            "cell_tracks": len(self.tracks_in.get(cell(worst[1].lat, worst[1].lon), ())),
        }


# ------------------------------------------------------------------ rules


@dataclass
class ProtectedZone:
    id: int
    name: str
    zone_type: str
    geometry: dict
    min_lat: float
    min_lon: float
    max_lat: float
    max_lon: float

    def distance(self, lat: float, lon: float, pad_deg: float) -> float | None:
        if not (self.min_lat - pad_deg <= lat <= self.max_lat + pad_deg):
            return None
        if not (self.min_lon - pad_deg <= lon <= self.max_lon + pad_deg):
            return None
        return distance_to_geometry_m(self.geometry, lat, lon)


def _hours(sec: float) -> str:
    return f"{sec / 3600:.1f} h" if sec >= 5400 else f"{sec / 60:.0f} min"


def rules(
    t: Track, cfg: dict, zones: list[ProtectedZone], harbours: list[ProtectedZone], base: Baseline | None
) -> Finding:
    f = Finding(track=t)
    segs = t.segments()
    gap_limit = cfg["gap_minutes_ais" if t.source_kind == "ais" else "gap_minutes_mda"] * 60

    def in_harbour(p: Point) -> bool:
        return any((d := h.distance(p.lat, p.lon, 0.1)) is not None and d == 0 for h in harbours)

    # Reporting gaps.
    for _a, b, dt, d, _sp, _hd in segs:
        if dt > gap_limit:
            f.reasons.append(
                Reason(
                    "gap",
                    f"No reports for {_hours(dt)}; reappeared {d / 1000:.1f} km away",
                    dt / 60,
                    cfg["gap_minutes_ais" if t.source_kind == "ais" else "gap_minutes_mda"],
                    b.at,
                    b.lat,
                    b.lon,
                )
            )
            break

    # Stops / loitering: consecutive slow segments (gaps excluded), outside harbours.
    run_start, run_dur, best = None, 0.0, None
    for a, _b, dt, _d, sp, _hd in segs:
        if sp < cfg["stop_speed_kn"] and dt <= gap_limit and not in_harbour(a):
            run_start = run_start or a
            run_dur += dt
            if best is None or run_dur > best[1]:
                best = (run_start, run_dur)
        else:
            run_start, run_dur = None, 0.0
    if best and best[1] >= cfg["stop_min_minutes"] * 60:
        p = best[0]
        f.reasons.append(
            Reason(
                "stop",
                f"Stopped or loitering for {_hours(best[1])} (speed under {cfg['stop_speed_kn']:g} kn)",
                best[1] / 60,
                cfg["stop_min_minutes"],
                p.at,
                p.lat,
                p.lon,
            )
        )

    # Protected areas: entry, else approach.
    pad = cfg["near_zone_m"] / 111_000 + 0.05
    entered, nearest = {}, None
    for p in t.points:
        for z in zones:
            d = z.distance(p.lat, p.lon, pad)
            if d is None:
                continue
            if d == 0 and z.id not in entered:
                entered[z.id] = (z, p)
            elif d < cfg["near_zone_m"] and (nearest is None or d < nearest[2]):
                nearest = (z, p, d)
    for z, p in entered.values():
        f.zone_ids.append(z.id)
        f.reasons.append(Reason("zone_entry", f"Entered {z.name}", None, None, p.at, p.lat, p.lon))
    if not entered and nearest:
        z, p, d = nearest
        f.zone_ids.append(z.id)
        f.reasons.append(
            Reason("approach", f"Came within {d / 1000:.1f} km of {z.name}", d, cfg["near_zone_m"], p.at, p.lat, p.lon)
        )

    # Off the usual lanes: positions in cells few past tracks used, for a track that is otherwise on them.
    if base is not None and base.n_cells and len(t.points) >= 3:
        limit = cfg["deviation_cell_min_tracks"]
        rare = [p for p in t.points if len(base.tracks_in.get(cell(p.lat, p.lon), ())) < limit]
        if len(rare) >= cfg["deviation_min_points"] and len(rare) < len(t.points):
            p = rare[0]
            f.reasons.append(
                Reason(
                    "deviation",
                    f"Left the usual traffic lanes: {len(rare)} positions where fewer than "
                    f"{cfg['deviation_cell_min_tracks']:g} past tracks went",
                    len(rare),
                    cfg["deviation_min_points"],
                    p.at,
                    p.lat,
                    p.lon,
                )
            )
    return f


def clusters(tracks: list[Track], cfg: dict, harbours: list[ProtectedZone]) -> dict[str, Reason]:
    """Vessels that stay together: slow, within radius of each other, for 30+ minutes, outside harbours.

    A track is in a cluster when at least cluster_min_tracks - 1 others kept that company. Ships passing in a
    lane are fast and apart again within minutes, so they do not count.
    """
    radius, window = cfg["cluster_radius_m"], cfg["cluster_window_minutes"] * 60
    slow = max(3.0, cfg["stop_speed_kn"] * 3)
    g = radius / 111_000
    buckets: dict[tuple, list] = defaultdict(list)
    for t in tracks:
        prev = None
        for p in t.points:
            sp = 0.0
            if prev:
                dt = (p.at - prev.at).total_seconds()
                sp = distance_m(prev.lat, prev.lon, p.lat, p.lon) / dt * KN if dt > 0 else 0.0
            prev = p
            if sp > slow:
                continue
            if any((d := h.distance(p.lat, p.lon, 0.1)) is not None and d == 0 for h in harbours):
                continue
            buckets[(math.floor(p.lat / g), math.floor(p.lon / g), int(p.at.timestamp() // window))].append((t.key, p))
    met: dict[str, dict[str, list]] = defaultdict(lambda: defaultdict(list))
    for (i, j, k), items in buckets.items():
        for key, p in items:
            for di in (-1, 0, 1):
                for dj in (-1, 0, 1):
                    for dk in (-1, 0, 1):
                        for k2, q in buckets.get((i + di, j + dj, k + dk), ()):
                            if (
                                k2 != key
                                and abs((q.at - p.at).total_seconds()) <= window / 2
                                and distance_m(p.lat, p.lon, q.lat, q.lon) <= radius
                            ):
                                met[key][k2].append(p)
    out: dict[str, Reason] = {}
    for key, partners in met.items():
        steady = {
            k2: ps
            for k2, ps in partners.items()
            if (max(x.at for x in ps) - min(x.at for x in ps)).total_seconds() >= 1800
        }
        if len(steady) + 1 >= cfg["cluster_min_tracks"]:
            p = min((x for ps in steady.values() for x in ps), key=lambda x: x.at)
            out[key] = Reason(
                "cluster",
                f"Stayed with {len(steady)} other vessel(s) within {radius / 1000:g} km for 30+ min, outside a harbour",
                len(steady) + 1,
                cfg["cluster_min_tracks"],
                p.at,
                p.lat,
                p.lon,
            )
    return out


def statistical(f: Finding, base: Baseline | None) -> None:
    if base is None or not base.ready:
        return
    score, worst = base.track_score(f.track)
    if score is None:
        return
    f.stat_score, f.stat_threshold = score, base.threshold
    if score > base.threshold:
        f.stat_flag = True
        f.reasons.append(
            Reason(
                "statistical",
                f"Unusual for this area: {worst['motion']} is seen in "
                f"{worst['p_bin'] * 100:.1f}% of past traffic here ({worst['cell_tracks']} past tracks)",
                score,
                round(base.threshold, 2),
                worst["at"],
                worst["lat"],
                worst["lon"],
            )
        )


def quality(t: Track) -> tuple[float, list[str]]:
    """Data quality 0-1 and plain-language uncertainty notes."""
    notes, q = [], 1.0
    if t.source_kind == "mda":
        notes.append("Sensor track without identity (not AIS): the same vessel may appear as several tracks.")
        confs = [p.confidence for p in t.points if p.confidence]
        if confs and confs.count("low") > len(confs) / 2:
            q *= 0.7
            notes.append("Most positions have low sensor confidence.")
    if len(t.points) < 3:
        q *= 0.7
        notes.append(f"Only {len(t.points)} position(s): too short to judge behaviour reliably.")
    gaps = [(b.at - a.at).total_seconds() for a, b in zip(t.points, t.points[1:], strict=False)]
    if gaps:
        med = sorted(gaps)[len(gaps) // 2]
        if med > 3600:
            q *= 0.85
            notes.append(f"Sparse track: a position every {_hours(med)} on average.")
    return round(q, 2), notes


def risk(f: Finding, q: float) -> int:
    raw = f.rule_score + (STAT_POINTS if f.stat_flag else 0)
    return int(round(min(100, raw) * (0.6 + 0.4 * q)))
