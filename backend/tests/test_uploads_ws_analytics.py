import hashlib
import uuid
from datetime import UTC, datetime

from sqlalchemy import select

from uavr.db.models import Evidence, LiveEvent
from uavr.db.session import sessionmaker
from uavr.live.hub import view_for
from uavr.security.principal import Principal
from uavr.storage import files

from .helpers import HSINCHU_MIL, XINYI, report


def media(data: bytes, slot="p1"):
    return {
        "slot": slot,
        "kind": "photo",
        "mime_type": "image/jpeg",
        "sha256": hashlib.sha256(data).hexdigest(),
        "size_bytes": len(data),
        "captured_at": datetime.now(UTC).isoformat(),
    }


async def test_tus_hooks_verify_hash(client, desks, staff):
    good, bad = b"\xff\xd8 real jpeg bytes", b"tampered"
    out = (
        await client.post("/v1/reports", json=report(XINYI, media=[media(good, "a"), media(b"x" * len(bad), "b")]))
    ).json()
    t_good, t_bad = out["uploads"]
    hook = lambda typ, tok, upload: {
        "Type": typ,
        "Event": {
            "Upload": upload,  # noqa: E731
            "HTTPRequest": {"Header": {"Upload-Token": [tok]}},
        },
    }
    r = await client.post("/v1/uploads/hooks", json=hook("pre-create", "forged.token", {"Size": 5}))
    assert r.json()["RejectUpload"] is True
    r = await client.post("/v1/uploads/hooks", json=hook("pre-create", t_good["upload_token"], {"Size": len(good)}))
    assert r.json()["ChangeFileInfo"]["ID"] == t_good["evidence_id"]

    for t, data in ((t_good, good), (t_bad, bad)):
        key = f"uploads/test-{uuid.uuid4()}"
        files.put_bytes(key, data, "image/jpeg")
        meta = {"evidence_id": t["evidence_id"]}
        r = await client.post(
            "/v1/uploads/hooks",
            json=hook(
                "post-finish",
                t["upload_token"],
                {"ID": "x", "MetaData": meta, "Storage": {"Type": "filestore", "Path": str(files.path_for(key))}},
            ),
        )
        assert r.status_code == 200
    async with sessionmaker()() as s:
        st = {str(e.id): e.status for e in (await s.execute(select(Evidence))).scalars()}
    assert st[t_good["evidence_id"]] == "verified" and st[t_bad["evidence_id"]] == "hash_mismatch"

    tc = staff(desks["TCPD-DISPATCH"])
    url = (await client.get(f"/v1/agency/evidence/{t_good['evidence_id']}/url", headers=tc)).json()["url"]
    assert "/v1/media/uploads/" in url
    path = url.split("/api", 1)[1]
    got = await client.get(path)
    assert got.status_code == 200 and got.content == good
    assert (await client.get(path.replace("s=", "s=0"))).status_code == 403  # tampered signature
    assert (await client.get("/v1/media/../../etc/passwd?e=9999999999&s=x")).status_code in (403, 404)


def P(desk, clearance=None, roles=("dispatcher",), field_unit=False, uid=None):
    return Principal(
        user_id=uid or uuid.uuid4(),
        username="u",
        display_name="",
        agency_id=desk.agency_id,
        desk_id=desk.id,
        roles=frozenset(roles),
        clearance=desk.clearance if clearance is None else clearance,
        field_unit=field_unit,
    )


async def test_live_events_respect_visibility(client, desks):
    await client.post("/v1/reports", json=report(HSINCHU_MIL))
    async with sessionmaker()() as s:
        ev = (await s.execute(select(LiveEvent).where(LiveEvent.kind == "case.created"))).scalar_one()
    joc, npa, kc = desks["MND-JOC"], desks["NPA-CMD"], desks["KCPD-DISPATCH"]
    assert view_for(P(joc), ev)["case"]["redacted"] is False
    assert view_for(P(npa), ev)["case"]["redacted"] is True
    assert view_for(P(kc), ev) is None
    nat = P(kc, roles=("national", "supervisor"), clearance=1)
    assert view_for(nat, ev)["case"]["redacted"] is True


async def test_websocket_handshake(desks):
    from starlette.testclient import TestClient

    from tests.conftest import staff_headers
    from uavr.db.session import dispose
    from uavr.main import app

    tok = staff_headers(desks["TCPD-DISPATCH"])["Authorization"][7:]
    await dispose()  # TestClient runs the app on its own event loop; it must build its own pool
    with TestClient(app) as tc, tc.websocket_connect(f"/v1/ws?token={tok}") as ws:
        hello = ws.receive_json()
        assert hello["type"] == "hello"
        ws.send_json({"type": "ping"})
        assert ws.receive_json()["type"] == "pong"


async def test_analytics_endpoints(client, desks, staff):
    for _ in range(3):
        r = report(
            XINYI,
            remote_id=[
                {
                    "transport": "bt4",
                    "received_at": datetime.now(UTC).isoformat(),
                    "uas_id": "REPEAT-1",
                    "lat": XINYI[0],
                    "lon": XINYI[1],
                    "height_m": 50,
                }
            ],
        )
        await client.post("/v1/reports", json=r)
        async with sessionmaker()() as s:
            from sqlalchemy import update

            from uavr.db.models import Incident

            await s.execute(update(Incident).values(active=False))
            await s.commit()
    from uavr.api.analytics import refresh_views

    async with sessionmaker()() as s:
        await refresh_views(s)
    h = staff(desks["TCPD-DISPATCH"], roles=("analyst",))
    summ = (await client.get("/v1/analytics/summary", headers=h)).json()
    assert summ["incidents"] == 3 and summ["with_remote_id"] == 3
    hot = (await client.get("/v1/analytics/hotspots", headers=h)).json()
    assert hot["cells"][0]["count"] == 3
    rep = (await client.get("/v1/analytics/repeat-offenders", headers=h)).json()
    assert rep["by_serial"][0]["serial"] == "REPEAT-1" and rep["by_serial"][0]["incidents"] == 3
    tod = (await client.get("/v1/analytics/time-of-day", headers=h)).json()
    assert sum(map(sum, tod["grid"])) == 3
    for path in ("zones", "response", "source-quality"):
        assert (await client.get(f"/v1/analytics/{path}", headers=h)).status_code == 200
    # Dispatchers without the analyst role are refused.
    assert (await client.get("/v1/analytics/summary", headers=staff(desks["TCPD-DISPATCH"]))).status_code == 403
