import json
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import select

from uavr.db.models import Case, Incident
from uavr.db.session import sessionmaker

from .helpers import SONGSHAN, XINYI, report

FEED = {"X-Feed-Key": "test-feed-key"}
EX = Path(__file__).resolve().parents[2] / "schemas" / "feeds" / "v1" / "examples"


def now(dt=0):
    return (datetime.now(UTC) + timedelta(seconds=dt)).isoformat().replace("+00:00", "Z")


def track(lat, lon, track_id="T-1", serial=None, t=0):
    tr = {
        "sensor_id": "TPE-RF-01",
        "sensor_kind": "rf",
        "track_id": track_id,
        "sensor_position": {"lat": lat - 0.01, "lon": lon},
        "points": [
            {"t": now(t - 3), "lat": lat - 0.0005, "lon": lon, "alt_m": 80},
            {"t": now(t), "lat": lat, "lon": lon, "alt_m": 85},
        ],
        "classification": {"target_type": "multirotor", "confidence": 0.9},
    }
    if serial:
        tr["rf"] = {"serial": serial, "pilot_position": {"lat": lat - 0.003, "lon": lon - 0.002}}
    return {"schema": "uavr.feed.sensor-track/1", "source_id": "vendor-test", "sent_at": now(), "tracks": [tr]}


async def test_feed_auth_and_schema(client):
    r = await client.post("/v1/ingest/adsb", json={}, headers={"X-Feed-Key": "wrong"})
    assert r.status_code == 401
    bad = json.loads((EX / "adsb.invalid.json").read_text())
    r = await client.post("/v1/ingest/adsb", json=bad, headers=FEED)
    assert r.status_code == 422
    paths = {e["path"] for e in r.json()["detail"]["errors"]}
    assert "/states/0/icao24" in paths and "/states/0/lat" in paths


async def test_all_valid_examples_ingest(client):
    for f in sorted(EX.glob("*.valid.json")):
        feed = f.name.split(".")[0]
        r = await client.post(f"/v1/ingest/{feed}", json=json.loads(f.read_text()), headers=FEED)
        assert r.status_code == 200, (feed, r.text)


async def test_sensor_track_creates_case_and_continues(client, desks):
    r = await client.post("/v1/ingest/sensor-track", json=track(*XINYI), headers=FEED)
    assert r.json()["observations"] == 1
    # The next update of the same track (moved 2.5 km) stays in the same incident.
    far = (XINYI[0] + 0.0225, XINYI[1])
    r = await client.post("/v1/ingest/sensor-track", json=track(*far, t=10), headers=FEED)
    assert r.json()["observations"] == 1
    async with sessionmaker()() as s:
        [inc] = (await s.execute(select(Incident))).scalars().all()
        assert inc.sensor_confirmed and inc.position_source == "sensor" and inc.observation_count == 2
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.classification >= 1  # sensor data is restricted


async def test_informant_report_joins_sensor_incident(client):
    await client.post("/v1/ingest/sensor-track", json=track(*XINYI), headers=FEED)
    r = await client.post("/v1/reports", json=report(XINYI))
    assert r.status_code == 201
    async with sessionmaker()() as s:
        assert len((await s.execute(select(Incident))).scalars().all()) == 1


async def test_adsb_proximity_escalates_to_critical(client):
    r = await client.post("/v1/reports", json=report(XINYI))
    async with sessionmaker()() as s:
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.severity == 1
    adsb = {
        "schema": "uavr.feed.adsb/1",
        "source_id": "adsb-test",
        "sent_at": now(),
        "states": [
            {
                "icao24": "8991a2",
                "callsign": "EVA12",
                "t": now(),
                "lat": XINYI[0] + 0.01,
                "lon": XINYI[1],
                "alt_geo_m": 400,
                "on_ground": False,
            }
        ],
    }
    r = await client.post("/v1/ingest/adsb", json=adsb, headers=FEED)
    assert r.json()["incidents_escalated"] == 1
    async with sessionmaker()() as s:
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.severity == 3
        inc = (await s.execute(select(Incident))).scalar_one()
        assert "near_manned_aircraft" in inc.severity_reasons and inc.adsb_nearby[0]["icao24"] == "8991a2"


async def test_permit_marks_likely_authorized(client, desks, staff):
    serial = "SERIAL-PERMIT-1"
    lat, lon = 25.0300, 121.5357  # yellow zone
    permit = {
        "schema": "uavr.feed.permit/1",
        "source_id": "caa",
        "sent_at": now(),
        "permits": [
            {
                "permit_no": "P-1",
                "serials": [serial],
                "valid_from": now(-3600),
                "valid_to": now(3600),
                "max_alt_m": 120,
                "area": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [lon - 0.01, lat - 0.01],
                            [lon + 0.01, lat - 0.01],
                            [lon + 0.01, lat + 0.01],
                            [lon - 0.01, lat + 0.01],
                            [lon - 0.01, lat - 0.01],
                        ]
                    ],
                },
            }
        ],
    }
    assert (await client.post("/v1/ingest/permit", json=permit, headers=FEED)).status_code == 200
    rid = [
        {
            "transport": "bt4",
            "received_at": now(),
            "uas_id": serial,
            "id_type": "serial",
            "lat": lat,
            "lon": lon,
            "height_m": 60,
        }
    ]
    await client.post("/v1/reports", json=report((lat, lon), remote_id=rid))
    async with sessionmaker()() as s:
        inc = (await s.execute(select(Incident))).scalar_one()
        assert inc.authorization == "likely_authorized"
        c = (await s.execute(select(Case))).unique().scalar_one()
        assert c.severity == 1
    # Registry lookup is audited.
    tc = staff(desks["TCPD-DISPATCH"])
    r = await client.get(f"/v1/agency/registry/{serial}", headers=tc)
    assert r.status_code == 200 and r.json()["permits"][0]["permit_no"] == "P-1"


async def test_no_permit_in_yellow_zone_is_medium(client):
    lat, lon = 25.0300, 121.5357
    rid = [{"transport": "bt4", "received_at": now(), "uas_id": "UNPERMITTED", "lat": lat, "lon": lon, "height_m": 60}]
    await client.post("/v1/reports", json=report((lat, lon), remote_id=rid))
    async with sessionmaker()() as s:
        inc = (await s.execute(select(Incident))).scalar_one()
        assert inc.authorization == "no_permit" and inc.auto_severity == 2


async def test_live_map_includes_aircraft(client, desks, staff):
    await client.post("/v1/reports", json=report(SONGSHAN))
    adsb = json.loads((EX / "adsb.valid.json").read_text())
    adsb["states"][0]["t"] = now()
    await client.post("/v1/ingest/adsb", json=adsb, headers=FEED)
    m = (await client.get("/v1/agency/map/live", headers=staff(desks["APB-OPS"]))).json()
    assert len(m["cases"]) == 1 and m["aircraft"][0]["icao24"] == "8991a2"
