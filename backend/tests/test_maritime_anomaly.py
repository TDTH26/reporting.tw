from datetime import UTC, datetime, timedelta

from uavr.anomaly import detect, settings
from uavr.anomaly.detect import Point, ProtectedZone, Track
from uavr.geoutil import bounds


def track(points, kind="ais", key="416000001"):
    return Track("t", kind, key, [Point(t, lat, lon) for t, lat, lon in points])


def line(t0, lat, lon, n, dlat=0.0, dlon=0.0, minutes=10):
    return [(t0 + timedelta(minutes=minutes * i), lat + dlat * i, lon + dlon * i) for i in range(n)]


T0 = datetime(2026, 10, 1, tzinfo=UTC)
CFG = settings.defaults()


def test_rules_explain_stop_gap_and_zone_entry():
    # 3 h stopped after moving: one stop reason with the duration.
    pts = line(T0, 24.0, 120.0, 6, dlat=0.03) + line(T0 + timedelta(hours=1), 24.15, 120.0, 19)
    f = detect.rules(track(pts), CFG, [], [], None)
    [r] = [r for r in f.reasons if r.code == "stop"]
    assert "3.2 h" in r.text and r.threshold == 120

    # 2 h without AIS reports: a gap reason.
    pts = line(T0, 24.0, 120.0, 4, dlat=0.03) + line(T0 + timedelta(hours=2.5), 24.3, 120.0, 3, dlat=0.03)
    f = detect.rules(track(pts), CFG, [], [], None)
    assert [r.code for r in f.reasons] == ["gap"] and "km away" in f.reasons[0].text
    # The same pause is normal for a sparse sensor track (gap limit 8 h).
    assert detect.rules(track(pts, kind="mda"), CFG, [], [], None).reasons == []

    ring = [[120.10, 24.10], [120.20, 24.10], [120.20, 24.20], [120.10, 24.20], [120.10, 24.10]]
    geom = {"type": "MultiPolygon", "coordinates": [[ring]]}
    zone = ProtectedZone(7, "Test restricted waters", "restricted_waters", geom, *bounds(geom))
    f = detect.rules(track(line(T0, 24.15, 120.0, 12, dlon=0.02)), CFG, [zone], [], None)
    assert [r.code for r in f.reasons] == ["zone_entry"] and f.zone_ids == [7]
    f = detect.rules(track(line(T0, 24.23, 120.0, 12, dlon=0.02)), CFG, [zone], [], None)
    assert [r.code for r in f.reasons] == ["approach"]


def test_cluster_needs_vessels_that_stay_together():
    stay = [track(line(T0, 24.0 + i * 0.002, 120.0, 8), key=f"k{i}") for i in range(3)]
    assert set(detect.clusters(stay, CFG, [])) == {"k0", "k1", "k2"}
    # Three ships passing the same point at 12 kn are not a cluster.
    passing = [track(line(T0, 23.9, 120.0 + i * 0.002, 8, dlat=0.033), key=f"p{i}") for i in range(3)]
    assert detect.clusters(passing, CFG, []) == {}


def test_quality_notes_for_incomplete_data():
    q, notes = detect.quality(track(line(T0, 24.0, 120.0, 2, minutes=180), kind="mda"))
    assert q < 0.7
    assert any("not AIS" in n for n in notes) and any("too short" in n for n in notes)


async def test_simulated_traffic_alerts_and_operator_workflow(client, desks, staff):
    from uavr.anomaly import engine
    from uavr.anomaly.simulate import simulate
    from uavr.db.session import sessionmaker

    async with sessionmaker()() as s:
        out = await simulate(s, seed=3)
        await s.commit()
        assert out["labels"]["normal"] > 300 and out["labels"]["cluster"] == 6
        run = await engine.run(s, "sim")
        await s.commit()
        assert run["alerts_new"] > 0
        ev = await engine.evaluate(s)
        await s.commit()
    combined, rules = ev.results["combined"], ev.results["rules"]
    assert combined["recall"] >= 0.9
    assert combined["false_alarms_per_100_normal"] < rules["false_alarms_per_100_normal"]

    cga = staff(desks["CGA-OPS"], roles=("dispatcher",))
    data = (await client.get("/v1/maritime/alerts", headers=cga)).json()
    alerts = data["alerts"]
    assert alerts and all(a["reasons"] and a["score"] >= 35 for a in alerts)
    assert alerts == sorted(alerts, key=lambda a: -a["score"])

    # Detail: explanation, track, timeline.
    a = alerts[0]
    d = (await client.get(f"/v1/maritime/alerts/{a['id']}", headers=cga)).json()
    assert d["track"] and d["events"][0]["action"] == "detected"

    # False alarm with a note: leaves the open list and stays quiet on the next run.
    r = await client.post(
        f"/v1/maritime/alerts/{a['id']}/status",
        headers=cga,
        json={"status": "false_alarm", "note": "fishing fleet, known", "suppress_hours": 12},
    )
    assert r.status_code == 200 and r.json()["suppress_until"]
    assert (
        await client.post(f"/v1/maritime/alerts/{a['id']}/notes", headers=cga, json={"text": "checked"})
    ).status_code == 200
    open_ids = {x["id"] for x in (await client.get("/v1/maritime/alerts", headers=cga)).json()["alerts"]}
    assert a["id"] not in open_ids
    async with sessionmaker()() as s:
        await engine.run(s, "sim")
        await s.commit()
    open_ids = {x["id"] for x in (await client.get("/v1/maritime/alerts", headers=cga)).json()["alerts"]}
    assert a["id"] not in open_ids
    d = (await client.get(f"/v1/maritime/alerts/{a['id']}", headers=cga)).json()
    assert [e["action"] for e in d["events"]][-2:] == ["false_alarm", "note"]

    # Escalate another alert: it becomes a routed case.
    b = next(x for x in alerts if x["id"] != a["id"])
    r = await client.post(f"/v1/maritime/alerts/{b['id']}/escalate", headers=cga)
    assert r.status_code == 200 and r.json()["status"] == "escalated" and r.json()["case_id"]

    # Thresholds: dispatchers read, supervisors change (validated), field officers have no access.
    assert (await client.put("/v1/maritime/settings", headers=cga, json={"stop_min_minutes": 60})).status_code == 403
    sup = staff(desks["CGA-OPS"], roles=("supervisor",))
    assert (await client.put("/v1/maritime/settings", headers=sup, json={"stop_min_minutes": 5})).status_code == 422
    r = await client.put("/v1/maritime/settings", headers=sup, json={"stop_min_minutes": 60})
    assert r.status_code == 200 and next(x for x in r.json() if x["key"] == "stop_min_minutes")["value"] == 60
    field = staff(desks["CGA-OPS"], roles=("field_officer",))
    assert (await client.get("/v1/maritime/alerts", headers=field)).status_code == 403

    ev = (await client.get("/v1/maritime/evaluation", headers=cga)).json()
    assert set(ev["results"]) == {"rules", "statistical", "combined"}
