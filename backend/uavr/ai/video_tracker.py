"""Persistent tracks across sampled camera frames, and behaviour alerts on them.

Detections from one frame are matched to the camera's active tracks by box overlap (or centre distance when the
model gave no box), greedily, best match first. Unmatched detections start new tracks; tracks not seen for
max_gap are lost. Behaviours are explainable and use image geometry only:
  loiter      seen for 60 s+ (3+ frames) while staying in a small part of the picture
  approaching the box grew 1.8x or more: the craft is coming towards the camera
  fast        the centre moved more than 5% of the frame width per second
  zone        the centre entered the camera's watch area (alert_zone polygon in image coordinates)
"""

import math
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db.models import VideoFeed, VideoTrack

MATCH_IOU = 0.05
MATCH_CENTRE = 0.2  # fraction of the frame
LOITER_S = 60
LOITER_SPREAD = 0.15
APPROACH_GROWTH = 1.8
FAST_PER_S = 0.05
CENTRE_X = {"left": 1 / 6, "center": 0.5, "right": 5 / 6}


@dataclass
class Det:
    craft_domain: str
    craft_type: str | None
    confidence: float
    box: tuple[float, float, float, float] | None  # x1, y1, x2, y2 in 0..1
    horizontal_position: str = "center"
    description: str = ""

    @property
    def centre(self) -> tuple[float, float]:
        if self.box:
            x1, y1, x2, y2 = self.box
            return (x1 + x2) / 2, (y1 + y2) / 2
        return CENTRE_X.get(self.horizontal_position, 0.5), 0.5


def area(b) -> float:
    return max(0.0, b[2] - b[0]) * max(0.0, b[3] - b[1])


def iou(a, b) -> float:
    ix = max(0.0, min(a[2], b[2]) - max(a[0], b[0]))
    iy = max(0.0, min(a[3], b[3]) - max(a[1], b[1]))
    inter = ix * iy
    union = area(a) + area(b) - inter
    return inter / union if union > 0 else 0.0


def _centre(p: dict) -> tuple[float, float]:
    return p.get("x", 0.5), p.get("y", 0.5)


def _match_score(t: VideoTrack, d: Det) -> float | None:
    if t.craft_domain != d.craft_domain or not t.path:
        return None
    last = t.path[-1]
    if last.get("box") and d.box:
        o = iou(last["box"], d.box)
        if o >= MATCH_IOU:
            return 1 + o
    cx, cy = _centre(last)
    dx, dy = d.centre
    dist = math.hypot(cx - dx, cy - dy)
    return 1 - dist / MATCH_CENTRE if dist <= MATCH_CENTRE else None


def associate(active: list[VideoTrack], dets: list[Det]) -> list[tuple[Det, VideoTrack | None]]:
    pairs = sorted(
        ((s, i, j) for i, d in enumerate(dets) for j, t in enumerate(active) if (s := _match_score(t, d)) is not None),
        reverse=True,
    )
    used_d, used_t, out = set(), set(), {}
    for _s, i, j in pairs:
        if i in used_d or j in used_t:
            continue
        used_d.add(i)
        used_t.add(j)
        out[i] = active[j]
    return [(d, out.get(i)) for i, d in enumerate(dets)]


def _inside(x: float, y: float, poly: list) -> bool:
    inside = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1], strict=False):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / ((y2 - y1) or 1e-12) + x1:
            inside = not inside
    return inside


def behaviours(path: list[dict], alert_zone: list | None) -> list[dict]:
    out = []
    if not path:
        return out
    t = [datetime.fromisoformat(p["t"]) for p in path]
    span = (t[-1] - t[0]).total_seconds()
    xs = [p.get("x", 0.5) for p in path]
    ys = [p.get("y", 0.5) for p in path]
    spread = max(max(xs) - min(xs), max(ys) - min(ys))
    if len(path) >= 3 and span >= LOITER_S and spread <= LOITER_SPREAD:
        out.append({"code": "loiter", "text": f"Hovering in view for {span:.0f} s"})
    boxes = [p["box"] for p in path if p.get("box")]
    if len(boxes) >= 2 and area(boxes[0]) > 0:
        growth = area(boxes[-1]) / area(boxes[0])
        if growth >= APPROACH_GROWTH:
            out.append({"code": "approaching", "text": f"Getting closer to the camera: {growth:.1f}x larger"})
    if len(path) >= 2 and span > 0:
        d = math.hypot(xs[-1] - xs[-2], ys[-1] - ys[-2])
        dt = (t[-1] - t[-2]).total_seconds() or 1
        if d / dt > FAST_PER_S:
            out.append(
                {"code": "fast", "text": f"Fast across the picture: {100 * d / dt:.0f}% of the frame per second"}
            )
    if alert_zone and len(alert_zone) >= 3 and _inside(xs[-1], ys[-1], alert_zone):
        out.append({"code": "zone", "text": "Inside the camera's watch area"})
    return out


def max_gap(feed: VideoFeed) -> timedelta:
    return timedelta(seconds=min(600, max(30, 3 * (feed.sample_interval_s or 120))))


async def update_tracks(
    session: AsyncSession, feed: VideoFeed, dets: list[Det], at: datetime, frame_key: str | None
) -> list[tuple[Det, VideoTrack]]:
    """Match a frame's detections to the camera's tracks and update them. The caller commits."""
    active = list(
        (
            await session.execute(
                select(VideoTrack).where(VideoTrack.feed_id == feed.id, VideoTrack.status == "active").with_for_update()
            )
        ).scalars()
    )
    gap = max_gap(feed)
    live = []
    for t in active:
        if at - t.last_at > gap:
            t.status = "lost"
        else:
            live.append(t)
    n = (await session.execute(select(func.count()).where(VideoTrack.feed_id == feed.id))).scalar_one()
    out = []
    for d, t in associate(live, dets):
        cx, cy = d.centre
        point = {
            "t": at.isoformat(),
            "box": list(d.box) if d.box else None,
            "x": round(cx, 4),
            "y": round(cy, 4),
            "conf": round(d.confidence, 2),
            "frame": frame_key,
        }
        if t is None:
            n += 1
            t = VideoTrack(
                feed_id=feed.id,
                key=f"{feed.id}-T{n}",
                status="active",
                craft_domain=d.craft_domain,
                craft_type=d.craft_type,
                first_at=at,
                last_at=at,
                hits=1,
                path=[point],
                behaviours=[],
            )
            session.add(t)
        else:
            t.path = [*t.path, point][-200:]
            t.hits, t.last_at = t.hits + 1, at
            t.craft_type = t.craft_type or d.craft_type
        t.behaviours = behaviours(t.path, feed.alert_zone)
        out.append((d, t))
    await session.flush()
    return out
