"""Simulated, labelled vessel traffic around Taiwan for testing and comparing the detectors.

A week of normal traffic (shipping lanes, fishing grounds) as training history, then a test day with the same
normal traffic plus injected behaviours, each labelled: stop, deviation, gap, zone_entry, cluster. Fishing boats
move slowly on purpose: they are normal, and show which method raises false alarms on them.
All rows are source_id "sim" (AIS-like, fake MMSIs 416xxxxxx); re-running replaces them.
"""

import math
import random
from datetime import UTC, datetime, timedelta

from sqlalchemy import insert
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import AnomalyLabel, VesselTrack
from ..domain.geo import distance_m
from .detect import KN, heading
from .engine import clear_source

SOURCE = "sim"
LANES = {
    "strait": [(25.9, 120.5), (25.0, 120.0), (24.0, 119.75), (23.0, 119.7), (22.2, 119.9)],
    "kaohsiung": [(21.9, 119.6), (22.35, 120.05), (22.55, 120.24)],
    "keelung": [(25.7, 122.3), (25.3, 121.95), (25.17, 121.78)],
    "east": [(25.4, 122.3), (24.0, 121.95), (23.0, 121.6), (22.0, 121.25)],
    "taichung": [(24.3, 119.85), (24.28, 120.3), (24.27, 120.45)],
}
DAILY = {"strait": 20, "kaohsiung": 8, "keelung": 6, "east": 6, "taichung": 6}
FISHING = [((23.45, 119.45), 22_000, 12), ((24.0, 120.12), 12_000, 8), ((24.47, 118.22), 8_000, 6)]
M_PER_DEG = 111_320.0


def _move(lat: float, lon: float, bearing: float, dist: float) -> tuple[float, float]:
    dlat = dist * math.cos(math.radians(bearing)) / M_PER_DEG
    dlon = dist * math.sin(math.radians(bearing)) / (M_PER_DEG * math.cos(math.radians(lat)))
    return lat + dlat, lon + dlon


def _along(path: list[tuple[float, float]], s: float) -> tuple[float, float, float]:
    """Point and bearing at distance s (m) along a polyline."""
    for a, b in zip(path, path[1:], strict=False):
        seg = distance_m(a[0], a[1], b[0], b[1])
        if s <= seg or b == path[-1]:
            f = min(1.0, s / seg) if seg else 0.0
            return a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, heading(a[0], a[1], b[0], b[1])
        s -= seg
    a, b = path[-2], path[-1]
    return b[0], b[1], heading(a[0], a[1], b[0], b[1])


def _length(path) -> float:
    return sum(distance_m(a[0], a[1], b[0], b[1]) for a, b in zip(path, path[1:], strict=False))


class Sim:
    def __init__(self, seed: int, now: datetime):
        self.r = random.Random(seed)
        self.now = now
        self.rows: list[dict] = []
        self.labels: list[dict] = []
        self.n = 0

    def _mmsi(self) -> str:
        self.n += 1
        return f"416{self.n:06d}"

    def _emit(self, mmsi, name, ship_type, pts):
        prev = None
        for t, lat, lon in pts:
            if t > self.now:
                break
            sog = cog = None
            if prev:
                dt = (t - prev[0]).total_seconds()
                if dt > 0:
                    sog = round(distance_m(prev[1], prev[2], lat, lon) / dt * KN, 1)
                    cog = round(heading(prev[1], prev[2], lat, lon), 1)
            self.rows.append(
                dict(
                    source_kind="ais",
                    source_id=SOURCE,
                    mmsi=mmsi,
                    name=name,
                    ship_type=ship_type,
                    at=t,
                    lat=round(lat, 5),
                    lon=round(lon, 5),
                    sog_kn=sog,
                    cog_deg=cog,
                )
            )
            prev = (t, lat, lon)

    def _label(self, mmsi, kind, start=None, end=None):
        self.labels.append(dict(source_id=SOURCE, track_id=mmsi, kind=kind, start_at=start, end_at=end))

    def transit(self, path, t0, *, kind="normal", stop=None, gap=None, speed=None):
        """Ship along a path. stop=(fraction, seconds): halt there; gap=(f0, f1): no reports between fractions."""
        r = self.r
        mmsi = self._mmsi()
        path = path if r.random() < 0.5 else path[::-1]
        offset = r.gauss(0, 1200)
        v = (speed or r.uniform(11, 16)) / KN
        total = _length(path)
        pts, s, t, stopped, ev = [], 0.0, t0, False, [None, None]
        while s < total:
            lat, lon, brg = _along(path, s)
            lat, lon = _move(lat, lon, brg + 90, offset)
            frac = s / total
            silent = gap and gap[0] <= frac <= gap[1]
            if not silent:
                pts.append((t, lat, lon))
            elif ev[0] is None:
                ev[0] = t
            if gap and frac > gap[1] and ev[0] and not ev[1]:
                ev[1] = t
            step = r.uniform(360, 600)
            if stop and not stopped and frac >= stop[0]:
                stopped, end = True, t + timedelta(seconds=stop[1])
                ev = [t, end]
                while t < end:
                    t += timedelta(seconds=r.uniform(360, 600))
                    dlat, dlon = _move(lat, lon, r.uniform(0, 360), r.uniform(0, 60))
                    pts.append((t, dlat, dlon))
            t += timedelta(seconds=step)
            s += v * step
        self._emit(mmsi, f"SIM {'CARGO' if kind == 'normal' else 'VESSEL'} {self.n}", 70, pts)
        self._label(mmsi, kind, ev[0], ev[1])
        return mmsi

    def fishing(self, center, radius, t0, hours):
        r = self.r
        mmsi = self._mmsi()
        lat, lon = _move(center[0], center[1], r.uniform(0, 360), r.uniform(0, radius * 0.6))
        brg, t, end, pts = r.uniform(0, 360), t0, t0 + timedelta(hours=hours), []
        while t < end:
            pts.append((t, lat, lon))
            step = r.uniform(480, 720)
            speed = r.uniform(0, 0.8) if r.random() < 0.35 else r.uniform(2, 4)
            brg += r.gauss(0, 35)
            nlat, nlon = _move(lat, lon, brg, speed / KN * step)
            if distance_m(center[0], center[1], nlat, nlon) > radius:
                brg += 180
            else:
                lat, lon = nlat, nlon
            t += timedelta(seconds=step)
        self._emit(mmsi, f"SIM FISHING {self.n}", 30, pts)
        self._label(mmsi, "normal")

    def normal_day(self, day_start):
        r = self.r
        for lane, n in DAILY.items():
            for _ in range(n):
                self.transit(LANES[lane], day_start + timedelta(hours=r.uniform(0, 24)))
        for center, radius, n in FISHING:
            for _ in range(n):
                self.fishing(center, radius, day_start + timedelta(hours=r.uniform(-4, 14)), r.uniform(8, 14))

    def meeting(self, point, t0, n=3):
        """n vessels converge on a point off the lanes, stay together ~90 min, then leave."""
        r = self.r
        for i in range(n):
            mmsi = self._mmsi()
            brg = i * 360 / n + r.uniform(-20, 20)
            start = _move(point[0], point[1], brg, 30_000)
            v = r.uniform(9, 12) / KN
            pts, t = [], t0
            for k in range(0, 30_000, int(v * 480)):
                pts.append((t, *_move(start[0], start[1], brg + 180, k)))
                t += timedelta(seconds=480)
            met = t
            while t < met + timedelta(minutes=90):
                pts.append((t, *_move(point[0], point[1], r.uniform(0, 360), r.uniform(0, 400))))
                t += timedelta(seconds=r.uniform(360, 600))
            for k in range(0, 30_000, int(v * 480)):
                pts.append((t, *_move(point[0], point[1], brg + 40, k)))
                t += timedelta(seconds=480)
            self._emit(mmsi, f"SIM VESSEL {self.n}", 0, pts)
            self._label(mmsi, "cluster", met, met + timedelta(minutes=90))

    def anomalies(self, day_start):
        r = self.r
        h = lambda lo, hi: day_start + timedelta(hours=r.uniform(lo, hi))  # noqa: E731
        for _ in range(3):
            self.transit(LANES["strait"], h(0, 10), kind="stop", stop=(r.uniform(0.3, 0.6), r.uniform(3, 4) * 3600))
        for side in (90, 90, -90):
            path = LANES["strait"]
            a, b = path[1], path[3]
            mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            detour = _move(mid[0], mid[1], heading(a[0], a[1], b[0], b[1]) + side, r.uniform(28_000, 40_000))
            self.transit([path[0], a, detour, b, path[4]], h(0, 10), kind="deviation")
        for lane in ("strait", "east", "strait"):
            self.transit(LANES[lane], h(0, 10), kind="gap", gap=(0.35, 0.6))
        self.transit([(22.30, 119.85), (22.70, 120.245), (22.80, 120.20)], h(2, 14), kind="zone_entry", speed=8)
        self.transit([(24.25, 118.65), (24.41, 118.43), (24.36, 118.25)], h(2, 14), kind="zone_entry", speed=8)
        self.meeting((24.70, 119.35), h(2, 12))
        self.meeting((22.85, 119.15), h(2, 12))


async def simulate(session: AsyncSession, seed: int = 7, days: int = 7) -> dict:
    """Replace the simulated traffic. The caller commits (then runs the engine / evaluation)."""
    now = datetime.now(UTC).replace(microsecond=0)
    sim = Sim(seed, now)
    test_day = now - timedelta(hours=24)
    for d in range(days, 0, -1):
        sim.normal_day(test_day - timedelta(days=d))
    sim.normal_day(test_day)
    sim.anomalies(test_day)
    await clear_source(session, SOURCE)
    for i in range(0, len(sim.rows), 2000):
        await session.execute(insert(VesselTrack), sim.rows[i : i + 2000])
    await session.execute(insert(AnomalyLabel), sim.labels)
    kinds: dict[str, int] = {}
    for lab in sim.labels:
        kinds[lab["kind"]] = kinds.get(lab["kind"], 0) + 1
    return {"positions": len(sim.rows), "tracks": len(sim.labels), "labels": kinds}
