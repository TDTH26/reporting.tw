"""Idempotent seed: python -m uavr.seed [--dev-feed-key KEY]"""

import argparse
import asyncio
import math

from shapely.affinity import scale
from shapely.geometry import MultiPolygon, Point, box, mapping
from sqlalchemy import select
from sqlalchemy.dialects.mysql import insert

from .db.models import Agency, Desk, FeedClient, Template, Zone
from .db.session import dispose, sessionmaker
from .feeds.validate import FEEDS
from .geoutil import bounds
from .security.hashing import keyed_hash
from .seed_data import AGENCIES, DESKS, TEMPLATES, ZONE_DOMAINS, ZONES


def _geo(spec) -> dict:
    gj = _shape(spec)
    min_lat, min_lon, max_lat, max_lon = bounds(gj)
    return {"geometry": gj, "min_lat": min_lat, "min_lon": min_lon, "max_lat": max_lat, "max_lon": max_lon}


def _shape(spec):
    if spec[0] == "bbox":
        _, s, w, n, e = spec
        g = box(w, s, e, n)
    else:
        _, lat, lon, r = spec
        deg = r / 111_320
        g = scale(Point(lon, lat).buffer(deg, quad_segs=16), xfact=1 / math.cos(math.radians(lat)), yfact=1)
    return mapping(MultiPolygon([g]))


async def seed(dev_feed_key: str | None = None) -> None:
    async with sessionmaker()() as s:
        for code, kind, name, zh in AGENCIES:
            await s.execute(
                insert(Agency)
                .values(code=code, kind=kind, name=name, name_zh=zh)
                .on_duplicate_key_update({"kind": kind, "name": name, "name_zh": zh})
            )
        agencies = {a.code: a.id for a in (await s.execute(select(Agency))).scalars()}
        for code, ag, name, zh, clearance, catch_all, staffed in DESKS:
            v = dict(
                agency_id=agencies[ag],
                name=name,
                name_zh=zh,
                clearance=clearance,
                is_catch_all=catch_all,
                always_staffed=staffed,
            )
            await s.execute(insert(Desk).values(code=code, **v).on_duplicate_key_update(v))
        desks = {d.code: d.id for d in (await s.execute(select(Desk))).unique().scalars()}
        for code, name, zh, zt, cls, pub, prio, shape, primary, backups, timeouts in ZONES:
            v = dict(
                name=name,
                name_zh=zh,
                zone_type=zt,
                classification=cls,
                published=pub,
                priority=prio,
                **_geo(shape),
                primary_desk_id=desks[primary],
                backup_chain=[desks[b] for b in backups],
                ack_timeouts=timeouts,
                domains=ZONE_DOMAINS.get(code, ["aerial", "surface", "subsurface", "shore"]),
                active=True,
            )
            await s.execute(insert(Zone).values(code=code, **v).on_duplicate_key_update(v))
        for code, kind, texts, false_report, kinds, sort in TEMPLATES:
            v = dict(
                kind=kind,
                texts=texts,
                counts_as_false_report=false_report,
                requested_kinds=kinds,
                sort=sort,
                active=True,
            )
            await s.execute(insert(Template).values(code=code, **v).on_duplicate_key_update(v))
        if dev_feed_key:
            h = keyed_hash("feed", dev_feed_key)
            exists = (await s.execute(select(FeedClient).where(FeedClient.key_hash == h))).scalar_one_or_none()
            if not exists:
                s.add(FeedClient(name="dev simulators", sources=[*FEEDS, "atreides"], classification=1, key_hash=h))
            else:
                exists.sources = [*FEEDS, "atreides"]  # new feeds become available to the dev key
        await s.commit()
    await dispose()
    print(f"seeded {len(AGENCIES)} agencies, {len(DESKS)} desks, {len(ZONES)} zones, {len(TEMPLATES)} templates")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dev-feed-key")
    asyncio.run(seed(ap.parse_args().dev_feed_key))
