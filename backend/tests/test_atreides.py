from sqlalchemy import func, select

from uavr import atreides
from uavr.db.models import VesselTrack
from uavr.db.session import sessionmaker

FEED = {"X-Feed-Key": "test-feed-key"}
HEADER = (
    "ContentType,FileLen,Latitude,Longitude,timestamp,PrimarySensorRole,PrimarySensorRoleConfidence,"
    "PrimarySensorRoleReasoning,PrimarySensorRoutePoints,PrimarySensorRouteSpanKm,SourceSensorRole,"
    "SourceSensorRoleConfidence,SourceSensorRoleReasoning,SourceSensorRoutePoints,SourceSensorRouteSpanKm\n"
)
MOVE = "mobile_asset,high,moves across 12.0 km with plausible max speed 9.1 km/h,3,12.0"
CSV = HEADER + "".join(
    [
        f"Coord,53,24.10,120.10,2026-04-02T09:00:00+00:00,{MOVE},mobile_asset,high,moves,3,12.0\n",
        f"Coord,53,24.15,120.15,2026-04-02T10:00:00+00:00,{MOVE},mobile_asset,high,moves,3,12.0\n",
        f"Coord,53,24.20,120.20,2026-04-02T11:00:00+00:00,{MOVE},mobile_asset,high,moves,3,12.0\n",
        "Coord,52,25.00,121.90,2026-04-02T09:30:00+00:00,ambiguous,low,insufficient or mixed evidence,1,0,"
        "fixed_site,high,stays within 0.13 km and looks stationary,5,0.13\n",
        "Coord,50,0,0,2026-04-02T09:40:00+00:00,ambiguous,low,x,1,0,ambiguous,low,x,1,0\n",
    ]
)


def admin(staff, desks):
    return staff(desks["NPA-CMD"], roles=("admin",), clearance=2)


def test_parse_and_tracks():
    rows, stats = atreides.parse(CSV)
    assert stats == {"rows": 5, "accepted": 4, "dropped": 1}  # 0,0 position dropped
    assert atreides.assign_tracks(rows, "ATR9") == 1
    route = {r["track_id"] for r in rows if r["role"] == "mobile_asset"}
    assert route == {"ATR9-R3-12.0"}
    [single] = [r for r in rows if r["role"] != "mobile_asset"]
    assert single["role"] == "fixed_site"  # ambiguous primary, fixed-site source view
    assert single["track_id"].startswith("ATR9-P")
    try:
        atreides.parse("a,b\n1,2\n")
        raise AssertionError("expected ParseError")
    except atreides.ParseError:
        pass


async def test_upload_summary_tracks_delete(client, desks, staff):
    files = {"file": ("sample.csv", CSV.encode(), "text/csv")}
    analyst = staff(desks["CGA-OPS"], roles=("analyst",))
    assert (await client.post("/v1/atreides/batches", files=files, headers=analyst)).status_code == 403
    r = await client.post("/v1/atreides/batches", files=files, headers=admin(staff, desks))
    assert r.status_code == 201, r.text
    b = r.json()
    assert (b["accepted"], b["dropped"], b["tracks"]) == (4, 1, 2)

    s = (await client.get("/v1/atreides/summary", headers=analyst)).json()
    assert s["detections"] == 4 and s["routes"] == 1 and s["single_contacts"] == 1
    assert s["by_role"] == {"mobile_asset": 3, "fixed_site": 1, "ambiguous": 0}

    routes = (await client.get("/v1/atreides/tracks?min_points=2", headers=analyst)).json()
    [t] = routes
    assert t["points"] == 3 and t["span_km"] == 12.0 and len(t["path"]) == 3
    assert t["path"][0] == [24.1, 120.1] and t["last"] == {"lat": 24.2, "lon": 120.2}
    fixed = (await client.get("/v1/atreides/tracks?role=fixed_site", headers=analyst)).json()
    assert [x["points"] for x in fixed] == [1]

    # Field officers have no access.
    field = staff(desks["CGA-OPS"], roles=("field_officer",))
    assert (await client.get("/v1/atreides/summary", headers=field)).status_code == 403

    async with sessionmaker()() as ses:
        n = await ses.execute(select(func.count()).select_from(VesselTrack).where(VesselTrack.source_id == "atreides"))
        assert n.scalar_one() == 4
    r = await client.delete(f"/v1/atreides/batches/{b['id']}", headers=admin(staff, desks))
    assert r.status_code == 204
    assert (await client.get("/v1/atreides/batches", headers=analyst)).json() == []
    async with sessionmaker()() as ses:
        n = await ses.execute(select(func.count()).select_from(VesselTrack).where(VesselTrack.source_id == "atreides"))
        assert n.scalar_one() == 0


async def test_feed_push(client):
    h = {**FEED, "Content-Type": "text/csv"}
    r = await client.post("/v1/ingest/atreides?filename=push.csv&shift_to_now=true", content=CSV.encode(), headers=h)
    assert r.status_code == 201, r.text
    b = r.json()
    assert b["filename"] == "push.csv" and b["received_via"] == "feed" and b["shifted_s"] > 0
    bad = await client.post("/v1/ingest/atreides", content=b"x,y\n1,2\n", headers=h)
    assert bad.status_code == 422
    assert (
        await client.post("/v1/ingest/atreides", content=CSV.encode(), headers={"X-Feed-Key": "nope"})
    ).status_code == 401
