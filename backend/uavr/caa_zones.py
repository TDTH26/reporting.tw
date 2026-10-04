"""Import the CAA drone zones (dronegis.caa.gov.tw, layer UAV_fs_ryg) into the zone table.

    python -m uavr.caa_zones                 # download and import
    python -m uavr.caa_zones --file ryg.json # import a saved GeoJSON FeatureCollection
    python -m uavr.caa_zones --dry-run       # show what would be imported

Red and yellow areas become zones with code CAA-<objectid>; the single green "permitted" area is skipped.
Military sites route to MND, Coast Guard sites to CGA, airports and heliports to the Aviation Police;
other county areas (critical infrastructure, schools, hospitals...) only raise severity and route by
jurisdiction. Re-running updates changed zones and deactivates zones the CAA has removed.
"""

import argparse
import asyncio
import json
import re
import sys
from dataclasses import dataclass
from datetime import UTC, datetime

import httpx
from shapely.geometry import MultiPolygon, mapping, shape
from shapely.validation import make_valid
from sqlalchemy import select, update
from sqlalchemy.dialects.mysql import insert

from .db.models import Desk, Zone
from .db.session import dispose, sessionmaker
from .geoutil import bounds

LAYER = "https://dronegis.caa.gov.tw/server/rest/services/Hosted/UAV_fs_ryg/FeatureServer/0/query"
# The CAA server rejects requests without a browser-like User-Agent.
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36",
    "Referer": "https://dronegis.caa.gov.tw/portal/apps/webappviewer/index.html",
}
PAGE = 2000
PREFIX = "CAA-"
SIMPLIFY_DEG = 0.00002  # about 2 m; keeps the console's zone layer small

AIR = ["aerial"]
AIR_SHORE = ["aerial", "shore"]

MILITARY = re.compile(
    r"營區|國軍|陸軍|海軍|空軍|軍事|軍營|軍備|基地|雷達|彈藥|指揮部|聯隊|飛彈|國防|憲兵|陣地|要塞|中科院|中山科學研究院"
)
NOT_MILITARY = re.compile(r"退除役|榮民|警察")
COAST_GUARD = re.compile(r"海巡|岸巡|海岸巡防")
INFRASTRUCTURE = re.compile(
    r"發電|變電|電廠|核能|淨水|水廠|水庫|中油|配氣|天然氣|油庫|機房|電信|台電|臺電|超高壓|開閉所|抽水站|自來水|配水|"
    r"攔河堰|監獄|看守所|戒治|矯正|煉|石化|儲運|科學園區|微波|輸氣|海纜|資料中心"
)


@dataclass
class Rule:
    zone_type: str
    name_en: str
    priority: int
    desk: str | None = None
    backup: tuple[str, ...] = ()
    domains: tuple[str, ...] = tuple(AIR)


def classify(p: dict) -> Rule | None:
    color, kind, name = p.get("空域顏色"), p.get("空域類型"), p.get("空域名稱") or ""
    if color not in ("紅區", "黃區"):
        return None  # green: flying allowed
    if kind == "4":
        return Rule("airport", "Airport / heliport no-fly area", 50, "APB-OPS", ("CAA-UAS",))
    if kind == "5":
        return Rule("yellow", "Airport area, no flying above 200 ft", 45, "APB-OPS", ("CAA-UAS",))
    if kind == "6":
        if "群島" in name:  # Dongsha / Nansha, garrisoned by the Coast Guard
            return Rule("outlying_islands_strict", "Restricted islands", 70, "CGA-OPS", ("MND-JOC",), tuple(AIR_SHORE))
        return Rule("military", "Restricted airspace (RCR)", 85, "MND-JOC", ("CAA-UAS",))
    if MILITARY.search(name) and not NOT_MILITARY.search(name):
        return Rule("military", "Military site", 90, "MND-JOC", ("NPA-CMD",), tuple(AIR_SHORE))
    if COAST_GUARD.search(name):
        return Rule("critical_infrastructure", "Coast Guard site", 75, "CGA-OPS", ("NPA-CMD",), tuple(AIR_SHORE))
    if color == "黃區":
        return Rule("yellow", "County restricted area (conditional)", 20)
    if INFRASTRUCTURE.search(name):
        return Rule("critical_infrastructure", "Critical infrastructure", 80, domains=tuple(AIR_SHORE))
    return Rule("red", "County no-fly area", 60)


def _expired(p: dict, now_ms: int) -> bool:
    end = p.get("有效日期迄")
    return isinstance(end, (int, float)) and end < now_ms


def _geometry(gj: dict) -> dict | None:
    s = shape(gj)
    if not s.is_valid:
        s = make_valid(s)
    s = s.simplify(SIMPLIFY_DEG, preserve_topology=True)
    if s.geom_type == "GeometryCollection":
        s = MultiPolygon([g for g in s.geoms if g.geom_type == "Polygon"])
    if s.geom_type == "Polygon":
        s = MultiPolygon([s])
    if s.geom_type != "MultiPolygon" or s.is_empty:
        return None
    polys = mapping(s)["coordinates"]
    return {
        "type": "MultiPolygon",
        "coordinates": [[[[round(x, 6), round(y, 6)] for x, y, *_ in ring] for ring in poly] for poly in polys],
    }


async def download() -> list[dict]:
    features: list[dict] = []
    async with httpx.AsyncClient(headers=HEADERS, timeout=120) as http:
        while True:
            r = await http.get(
                LAYER,
                params={
                    "where": "1=1",
                    "outFields": "*",
                    "outSR": 4326,
                    "orderByFields": "objectid",
                    "resultOffset": len(features),
                    "resultRecordCount": PAGE,
                    "f": "geojson",
                },
            )
            r.raise_for_status()
            page = r.json().get("features", [])
            features += page
            if len(page) < PAGE:
                return features


def build(features: list[dict], desks: dict[str, int]) -> tuple[list[dict], int]:
    now_ms = int(datetime.now(UTC).timestamp() * 1000)
    rows, skipped = [], 0
    for f in features:
        p = f.get("properties") or {}
        rule = classify(p)
        geom = _geometry(f["geometry"]) if rule and f.get("geometry") and not _expired(p, now_ms) else None
        if geom is None:
            skipped += 1
            continue
        name = (p.get("空域名稱") or "").strip() or f"{p.get('objectid')}"
        min_lat, min_lon, max_lat, max_lon = bounds(geom)
        rows.append(
            {
                "code": f"{PREFIX}{p['objectid']}",
                "name": f"{rule.name_en}: {name}"[:200],
                "name_zh": f"{p.get('空域類別名稱') or ''}：{name}"[:200],
                "zone_type": rule.zone_type,
                "classification": 0,
                # The informant app links to the CAA's own map; these stay out of /v1/public/zones.
                "published": False,
                "priority": rule.priority,
                "geometry": geom,
                "min_lat": min_lat,
                "min_lon": min_lon,
                "max_lat": max_lat,
                "max_lon": max_lon,
                "primary_desk_id": desks.get(rule.desk) if rule.desk else None,
                "backup_chain": [desks[c] for c in rule.backup if c in desks],
                "ack_timeouts": {},
                "domains": list(rule.domains),
                "active": True,
            }
        )
    return rows, skipped


async def store(rows: list[dict]) -> tuple[int, int]:
    async with sessionmaker()() as s:
        for i in range(0, len(rows), 200):
            chunk = rows[i : i + 200]
            stmt = insert(Zone).values(chunk)
            cols = [k for k in chunk[0] if k != "code"]
            await s.execute(stmt.on_duplicate_key_update({k: stmt.inserted[k] for k in cols}))
        gone = await s.execute(
            update(Zone)
            .where(Zone.code.startswith(PREFIX), Zone.code.not_in([r["code"] for r in rows]), Zone.active)
            .values(active=False)
        )
        await s.commit()
        return len(rows), gone.rowcount


async def main(a: argparse.Namespace) -> None:
    if a.file:
        with open(a.file) as fh:  # noqa: ASYNC230 - one-off CLI read
            features = json.load(fh)["features"]
    else:
        features = await download()
    async with sessionmaker()() as s:
        desks = {d.code: d.id for d in (await s.execute(select(Desk))).unique().scalars()}
    rows, skipped = build(features, desks)
    by_type: dict[str, int] = {}
    for r in rows:
        by_type[r["zone_type"]] = by_type.get(r["zone_type"], 0) + 1
    print(f"{len(features)} CAA features: {len(rows)} zones, {skipped} skipped (green, expired or empty)")
    print("  " + ", ".join(f"{k}={v}" for k, v in sorted(by_type.items())))
    if not a.dry_run:
        n, gone = await store(rows)
        print(f"imported {n} zones, deactivated {gone} removed by the CAA")
    await dispose()


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", help="GeoJSON FeatureCollection instead of downloading")
    ap.add_argument("--dry-run", action="store_true")
    asyncio.run(main(ap.parse_args()))
    sys.exit(0)
