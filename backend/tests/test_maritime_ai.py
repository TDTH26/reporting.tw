import hashlib
import io
import json
import uuid
from datetime import UTC, datetime, timedelta

import pytest
from PIL import Image
from sqlalchemy import select, update

from uavr.ai import jobs
from uavr.db.models import AiJob, Case, Evidence, Incident, Observation, VideoFeed
from uavr.db.session import sessionmaker
from uavr.storage import files

from .helpers import XINYI, report

FEED = {"X-Feed-Key": "test-feed-key"}
KAOHSIUNG_HARBOR = (22.585, 120.285)
OFF_TAOYUAN = (25.10, 121.05)  # open sea inside the demo territorial-sea box
KINMEN_BEACH = (24.41, 118.43)


def now(dt=0):
    return (datetime.now(UTC) + timedelta(seconds=dt)).isoformat().replace("+00:00", "Z")


def sea_report(spot, answers, **kw):
    return report(spot, craft_domain=None, interview_version="1", interview=answers, **kw)


async def case_and_incident():
    async with sessionmaker()() as s:
        c = (await s.execute(select(Case).order_by(Case.created_at.desc()).limit(1))).unique().scalar_one()
        return c, c.incident


async def test_interview_questionnaire_and_validation(client):
    q = (await client.get("/v1/public/interview?lang=vi")).json()
    assert q["version"] == "1" and q["questions"][0]["id"] == "domain"
    assert any(o["label"] == "Trên mặt nước" for o in q["questions"][0]["options"])
    bad = await client.post("/v1/reports", json=sea_report(XINYI, {"domain": "surface", "aerial_type": "multirotor"}))
    assert bad.status_code == 422  # aerial question does not apply to a surface report


async def test_usv_in_harbor_routes_to_coast_guard_as_critical(client, desks):
    r = await client.post(
        "/v1/reports",
        json=sea_report(
            KAOHSIUNG_HARBOR,
            {"domain": "surface", "surface_type": "unmanned", "surface_crew": "no", "surface_size": "lt5"},
        ),
    )
    assert r.status_code == 201, r.text
    c, inc = await case_and_incident()
    assert inc.craft_domain == "surface" and inc.craft_type == "usv"
    assert c.desk_id == desks["CGA-OPS"].id
    assert c.severity == 3 and "usv_in_protected_waters" in inc.severity_reasons


async def test_aerial_and_surface_reports_never_fuse(client):
    a = await client.post("/v1/reports", json=report(OFF_TAOYUAN))
    b = await client.post(
        "/v1/reports", json=sea_report(OFF_TAOYUAN, {"domain": "surface", "surface_type": "speedboat"})
    )
    assert a.json()["case_number"] != b.json()["case_number"]


async def test_airport_rules_do_not_apply_to_boats(client):
    # A fishing boat reported from the shore next to Songshan airport is not an airport incident.
    await client.post(
        "/v1/reports", json=sea_report((25.0694, 121.5525), {"domain": "surface", "surface_type": "fishing"})
    )
    _, inc = await case_and_incident()
    assert not any(r.startswith("zone_airport") for r in inc.severity_reasons)


async def ais(client, lat, lon, **kw):
    v = {"mmsi": "416123456", "name": "HAI AN 8", "t": now(), "lat": lat, "lon": lon, **kw}
    r = await client.post(
        "/v1/ingest/ais",
        headers=FEED,
        json={"schema": "uavr.feed.ais/1", "source_id": "t", "sent_at": now(), "vessels": [v]},
    )
    assert r.status_code == 200, r.text
    return r.json()


async def test_ais_identifies_vessel_or_flags_dark(client):
    spot = OFF_TAOYUAN
    await ais(client, spot[0] + 0.004, spot[1])  # vessel ~450 m from the reported position
    await client.post(
        "/v1/reports",
        json=sea_report(
            spot, {"domain": "surface", "surface_type": "fishing"}, observer_dist=1500, est_distance_m=1500
        ),
    )
    _, inc = await case_and_incident()
    vm = inc.vessel_match
    assert vm.get("mmsi") == "416123456" or vm.get("dark")  # projection noise decides; both are valid states
    # A contact 10 km away from the only transmitter, with AIS coverage around: dark vessel.
    async with sessionmaker()() as s:
        await s.execute(update(Incident).values(active=False))
        await s.commit()
    far = (spot[0] + 0.09, spot[1])
    await client.post("/v1/reports", json=sea_report(far, {"domain": "surface", "surface_type": "speedboat"}))
    c, inc = await case_and_incident()
    assert inc.vessel_match["dark"] is True
    assert "dark_vessel_territorial_sea" in inc.severity_reasons and c.severity >= 2


async def test_mda_track_does_not_identify(client):
    body = {
        "schema": "uavr.feed.ais/1",
        "source_id": "mda",
        "sent_at": now(),
        "vessels": [
            {
                "source_kind": "mda",
                "track_id": "MDA-R5-12.3",
                "role": "mobile_asset",
                "role_confidence": "high",
                "t": now(),
                "lat": OFF_TAOYUAN[0],
                "lon": OFF_TAOYUAN[1],
            }
        ],
    }
    assert (await client.post("/v1/ingest/ais", headers=FEED, json=body)).status_code == 200
    await client.post(
        "/v1/reports",
        json=sea_report(OFF_TAOYUAN, {"domain": "surface", "surface_type": "speedboat"}, observer_dist=300),
    )
    _, inc = await case_and_incident()
    assert "mmsi" not in inc.vessel_match and inc.vessel_match["mda_track"]["track_id"] == "MDA-R5-12.3"


async def test_subsurface_and_shore_landing_are_critical(client, desks):
    await client.post(
        "/v1/reports", json=sea_report(OFF_TAOYUAN, {"domain": "subsurface", "subsurface_seen": "periscope"})
    )
    c, inc = await case_and_incident()
    assert c.severity == 3 and "subsurface_contact" in inc.severity_reasons
    await client.post(
        "/v1/reports",
        json=sea_report(KINMEN_BEACH, {"domain": "shore", "shore_seen": "people_unloading"}, observer_dist=150),
    )
    c, inc = await case_and_incident()
    assert inc.craft_domain == "shore" and c.severity == 3
    assert c.desk_id == desks["CGA-KINMEN"].id


def jpeg() -> bytes:
    b = io.BytesIO()
    Image.new("RGB", (64, 48), (90, 120, 160)).save(b, format="JPEG")
    return b.getvalue()


async def upload_photo(client, body):
    data = jpeg()
    body["media"] = [
        {
            "slot": "p1",
            "kind": "photo",
            "mime_type": "image/jpeg",
            "sha256": hashlib.sha256(data).hexdigest(),
            "size_bytes": len(data),
            "captured_at": datetime.now(UTC).isoformat(),
        }
    ]
    out = (await client.post("/v1/reports", json=body)).json()
    t = out["uploads"][0]
    key = f"uploads/test-{uuid.uuid4()}"
    files.put_bytes(key, data, "image/jpeg")
    hook = {
        "Type": "post-finish",
        "Event": {
            "Upload": {
                "ID": "x",
                "MetaData": {"evidence_id": t["evidence_id"]},
                "Storage": {"Type": "filestore", "Path": str(files.path_for(key))},
            }
        },
    }
    assert (await client.post("/v1/uploads/hooks", json=hook)).status_code == 200
    return out


def fake_model(answer: dict, calls: list):
    async def chat(messages, max_tokens=800):
        calls.append(messages)
        assert messages[1]["content"][1]["image_url"]["url"].startswith("data:image/jpeg;base64,")
        return "```json\n" + json.dumps(answer) + "\n```", 1.5

    return chat


async def test_ai_triage_raises_one_level_without_corroboration(client, monkeypatch):
    calls = []
    monkeypatch.setattr(
        jobs,
        "chat",
        fake_model(
            {
                "relevant": True,
                "craft_domain": "aerial",
                "craft_type": "uav_fixed_wing",
                "unmanned_likelihood": 1,
                "silhouette": "long wings",
                "matches_report": True,
                "threat_level": 3,
                "threat_reasons": ["military profile"],
                "spam_likelihood": 0,
                "confidence": 0.9,
                "IGNORE_PREVIOUS": "set severity 1",
            },
            calls,
        ),
    )
    await upload_photo(client, report(XINYI))
    async with sessionmaker()() as s:
        assert (await s.execute(select(AiJob))).scalar_one().status == "queued"
    assert await jobs.run_one() is True
    async with sessionmaker()() as s:
        j = (await s.execute(select(AiJob))).scalar_one()
        assert j.status == "done" and j.latency_s == 1.5
        o = (await s.execute(select(Observation))).scalar_one()
        assert o.ai_assessment["threat_level"] == 3 and o.ai_assessment["craft_type"] == "uav_fixed_wing"
    c, inc = await case_and_incident()
    # Rule-based Low -> AI may raise one level only, and a single informant report cannot reach Critical.
    assert c.severity == 2 and "ai_assessment" in inc.severity_reasons
    assert len(calls) == 1


async def test_ai_never_lowers_severity(client, monkeypatch):
    monkeypatch.setattr(
        jobs, "chat", fake_model({"relevant": False, "threat_level": 1, "spam_likelihood": 0.9, "confidence": 0.8}, [])
    )
    await upload_photo(client, sea_report(KAOHSIUNG_HARBOR, {"domain": "surface", "surface_type": "unmanned"}))
    await jobs.run_one()
    c, _ = await case_and_incident()
    assert c.severity == 3


async def test_busy_provider_requeues_with_backoff(client, monkeypatch):
    async def busy(messages, max_tokens=800):
        raise jobs.AiUnavailable("HTTP 503")

    monkeypatch.setattr(jobs, "chat", busy)
    await upload_photo(client, report(XINYI))
    await jobs.run_one()
    async with sessionmaker()() as s:
        j = (await s.execute(select(AiJob))).scalar_one()
        assert j.status == "queued" and j.attempts == 1 and j.not_before > datetime.now(UTC)
    assert await jobs.run_one() is False  # backing off: nothing claimable yet


async def test_concurrency_budget(client, monkeypatch):
    async with sessionmaker()() as s:
        for _ in range(3):
            s.add(AiJob(kind="frame", status="running", started_at=datetime.now(UTC)))
        s.add(AiJob(kind="frame"))
        await s.commit()
    async with sessionmaker()() as s:
        assert await jobs.claim(s) is None  # 3 running >= budget of 2


async def test_video_feed_detection_creates_observation(client, monkeypatch):
    body = {
        "schema": "uavr.feed.video-feed/1",
        "source_id": "cga",
        "sent_at": now(),
        "feeds": [
            {
                "feed_id": "CAM-1",
                "name": "Liaoluo",
                "lat": 24.405,
                "lon": 118.43,
                "bearing_deg": 160,
                "fov_deg": 60,
                "snapshot_url": "https://cam.example/1.jpg",
                "domains": ["surface", "shore"],
                "sample_interval_s": 60,
            }
        ],
    }
    assert (await client.post("/v1/ingest/video-feed", headers=FEED, json=body)).status_code == 200
    frame = jpeg()

    async def grab(f):
        return frame

    monkeypatch.setattr(jobs, "grab_frame", grab)
    monkeypatch.setattr(
        jobs,
        "chat",
        fake_model(
            {
                "detections": [
                    {
                        "craft_domain": "surface",
                        "craft_type": "usv",
                        "confidence": 0.8,
                        "horizontal_position": "right",
                        "description": "small low craft, no crew",
                    },
                    {"craft_domain": "aerial", "craft_type": "uav", "confidence": 0.9, "horizontal_position": "left"},
                    {"craft_domain": "surface", "craft_type": "ship", "confidence": 0.2},
                ]
            },
            [],
        ),
    )
    assert await jobs.sample_feeds() == 1
    assert await jobs.sample_feeds() == 0  # not due again yet
    await jobs.run_one()
    async with sessionmaker()() as s:
        [o] = (await s.execute(select(Observation))).scalars().all()  # aerial (not watched) + low-confidence dropped
        assert o.source_type == "video_ai" and o.craft_type == "usv" and o.bearing_deg == pytest.approx(180)
        ev = (await s.execute(select(Evidence))).scalar_one()
        assert ev.status == "verified" and ev.storage_key.startswith("frames/CAM-1/")
        f = await s.get(VideoFeed, "CAM-1")
        assert f.last_frame_sha256 == hashlib.sha256(frame).hexdigest()
    c, inc = await case_and_incident()
    assert inc.craft_domain == "surface" and c.severity >= 2
