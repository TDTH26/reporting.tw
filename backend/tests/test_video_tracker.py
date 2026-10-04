import io
import json
from datetime import UTC, datetime, timedelta

from PIL import Image
from sqlalchemy import select

from uavr.ai import jobs, video_tracker
from uavr.ai.video_tracker import Det
from uavr.db.models import Observation, VideoTrack
from uavr.db.session import sessionmaker

T0 = datetime(2026, 10, 3, 12, 0, tzinfo=UTC)


def path(*points):
    return [{"t": (T0 + timedelta(seconds=s)).isoformat(), "x": x, "y": y, "box": box} for s, x, y, box in points]


def test_behaviours_loiter_approach_fast_zone():
    hover = path((0, 0.5, 0.5, None), (40, 0.52, 0.5, None), (80, 0.51, 0.52, None))
    assert [b["code"] for b in video_tracker.behaviours(hover, None)] == ["loiter"]
    grow = path((0, 0.5, 0.5, [0.45, 0.45, 0.5, 0.5]), (10, 0.5, 0.5, [0.42, 0.42, 0.5, 0.5]))
    assert "approaching" in [b["code"] for b in video_tracker.behaviours(grow, None)]
    fast = path((0, 0.1, 0.5, None), (5, 0.6, 0.5, None))
    assert "fast" in [b["code"] for b in video_tracker.behaviours(fast, None)]
    zone = [[0.4, 0.4], [0.6, 0.4], [0.6, 0.6], [0.4, 0.6]]
    assert "zone" in [b["code"] for b in video_tracker.behaviours(hover, zone)]
    assert "zone" not in [b["code"] for b in video_tracker.behaviours(fast, zone)]


def test_association_prefers_overlap_and_keeps_domains_apart():
    a = VideoTrack(key="A", craft_domain="aerial", path=[{"x": 0.2, "y": 0.2, "box": [0.1, 0.1, 0.3, 0.3]}])
    b = VideoTrack(key="B", craft_domain="aerial", path=[{"x": 0.8, "y": 0.2, "box": [0.7, 0.1, 0.9, 0.3]}])
    s = VideoTrack(key="S", craft_domain="surface", path=[{"x": 0.2, "y": 0.5, "box": None}])
    dets = [
        Det("aerial", "uav", 0.9, (0.72, 0.12, 0.92, 0.32)),
        Det("aerial", "uav", 0.9, (0.12, 0.1, 0.32, 0.3)),
        Det("surface", "small_boat", 0.8, None, "left"),
        Det("aerial", "uav", 0.9, (0.45, 0.7, 0.5, 0.75)),
    ]
    got = [t.key if t else None for _d, t in video_tracker.associate([a, b, s], dets)]
    assert got == ["B", "A", "S", None]


def jpeg() -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (64, 48), (120, 160, 200)).save(buf, "JPEG")
    return buf.getvalue()


async def test_replayed_frames_build_one_track_with_behaviours(client, desks, staff, monkeypatch):
    admin = staff(desks["NPA-CMD"], roles=("admin",), clearance=2)
    feed = {
        "id": "CAM-PIER",
        "name": "Pier camera",
        "lat": 22.61,
        "lon": 120.27,
        "bearing_deg": 270,
        "fov_deg": 60,
        "domains": ["aerial"],
        "sample_interval_s": 10,
        "alert_zone": [[0.4, 0.3], [0.7, 0.3], [0.7, 0.7], [0.4, 0.7]],
    }
    assert (await client.put("/v1/admin/video-feeds/CAM-PIER", json=feed, headers=admin)).status_code == 200
    bad = {**feed, "alert_zone": [[0.1, 0.1], [2, 0.1], [0.5, 0.5]]}
    assert (await client.put("/v1/admin/video-feeds/CAM-PIER", json=bad, headers=admin)).status_code == 422

    # A drone flying in from the left, growing as it approaches, ending inside the watch area.
    boxes = [[100, 400, 160, 450], [260, 390, 340, 460], [440, 370, 560, 480], [500, 340, 680, 520]]
    replies = iter(
        {"detections": [{"craft_domain": "aerial", "craft_type": "uav_multirotor", "confidence": 0.9, "box": b}]}
        for b in boxes
    )

    async def chat(messages, max_tokens=800):
        return json.dumps(next(replies)), 0.5

    monkeypatch.setattr(jobs, "chat", chat)
    start = datetime.now(UTC) - timedelta(seconds=40)
    for i in range(len(boxes)):
        at = (start + timedelta(seconds=10 * i)).isoformat()
        r = await client.post(
            "/v1/admin/video-feeds/CAM-PIER/frames",
            headers=admin,
            files={"file": ("f.jpg", jpeg(), "image/jpeg")},
            data={"captured_at": at},
        )
        assert r.status_code == 202, r.text
    assert (
        await client.post(
            "/v1/admin/video-feeds/CAM-PIER/frames",
            headers=admin,
            files={"file": ("f.png", b"not a jpeg", "image/png")},
        )
    ).status_code == 422
    for _ in boxes:
        assert await jobs.run_one() is True

    data = (await client.get("/v1/agency/video-feeds/CAM-PIER/tracks", headers=staff(desks["NPA-CMD"]))).json()
    [t] = data["tracks"]
    assert t["key"] == "CAM-PIER-T1" and t["hits"] == 4 and len(t["path"]) == 4
    codes = {b["code"] for b in t["behaviours"]}
    assert {"approaching", "zone"} <= codes
    assert t["last_frame_url"] and "/v1/media/frames/CAM-PIER/" in t["last_frame_url"]
    assert t["case"] and t["case"]["case_number"].startswith("UAV-")  # the case this track fed

    async with sessionmaker()() as s:
        obs = (await s.execute(select(Observation).order_by(Observation.observed_at))).scalars().all()
        assert {o.source_id for o in obs} == {"feed:CAM-PIER:CAM-PIER-T1"}
        # Bearing from the box centre: first box centred at x=0.13 -> 270 + (0.13 - 0.5) * 60
        assert abs(obs[0].bearing_deg - (270 + (0.13 - 0.5) * 60)) < 0.5
        assert "watch area" in obs[-1].description
