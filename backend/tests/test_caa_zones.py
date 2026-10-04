from sqlalchemy import delete

from uavr import caa_zones
from uavr.db.models import Zone
from uavr.db.session import sessionmaker

from .helpers import report

MIAOLI = (24.47, 120.91)  # no demo zone here


def feature(oid, name, color="紅區", kind="7", center=MIAOLI, d=0.01):
    lat, lon = center
    ring = [[lon - d, lat - d], [lon + d, lat - d], [lon + d, lat + d], [lon - d, lat + d], [lon - d, lat - d]]
    return {
        "type": "Feature",
        "properties": {
            "objectid": oid,
            "空域名稱": name,
            "空域顏色": color,
            "空域類型": kind,
            "空域類別名稱": "縣市政府限制使用範圍",
        },
        "geometry": {"type": "Polygon", "coordinates": [ring]},
    }


def test_classify():
    def zt(name, color="紅區", kind="7"):
        r = caa_zones.classify({"空域名稱": name, "空域顏色": color, "空域類型": kind})
        return r and (r.zone_type, r.desk)

    assert zt("金344 陸軍營區") == ("military", "MND-JOC")
    assert zt("桃711 退除役官兵職業訓練中心第3校區") == ("red", None)
    assert zt("基28 海巡機關") == ("critical_infrastructure", "CGA-OPS")
    assert zt("中232 北屯二次變電所") == ("critical_infrastructure", None)
    assert zt("竹縣112 新竹縣興隆國民小學") == ("red", None)
    assert zt("嘉市43 嘉義市崇文國民小學", "黃區") == ("yellow", None)
    assert zt("臺北松山國際機場禁止施放範圍", kind="4") == ("airport", "APB-OPS")
    assert zt("限航區RCR6", kind="6") == ("military", "MND-JOC")
    assert zt("東沙群島", kind="6") == ("outlying_islands_strict", "CGA-OPS")
    assert zt(None, "綠區") is None


async def test_import_routes_military_site_to_mnd(client, desks, staff):
    ids = {code: d.id for code, d in desks.items()}
    try:
        rows, skipped = caa_zones.build([feature(1, "苗999 國軍營區"), feature(2, None, color="綠區", d=1)], ids)
        assert skipped == 1
        assert await caa_zones.store(rows) == (1, 0)
        # Re-import without the camp deactivates it.
        assert await caa_zones.store(caa_zones.build([feature(3, "苗998 國小", center=(23.0, 120.2))], ids)[0]) == (
            1,
            1,
        )
        assert await caa_zones.store(rows) == (1, 1)

        r = await client.post("/v1/reports", json=report(MIAOLI))
        assert r.status_code == 201, r.text
        q = (await client.get("/v1/agency/queue", headers=staff(desks["MND-JOC"]))).json()
        [c] = q["cases"]
        assert c["severity"] == 3  # military zone
    finally:
        async with sessionmaker()() as s:
            await s.execute(delete(Zone).where(Zone.code.startswith(caa_zones.PREFIX)))
            await s.commit()
