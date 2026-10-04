"""Atreides maritime sensor (MDA) exports: parsing, track reconstruction and import.

The export (e.g. "MDA Sensor Mini Sample_APRIL_26.csv") is not AIS: each row is a timestamped position with a
role classification from two sensor views (primary / source): mobile_asset, fixed_site or ambiguous, with a
confidence and a plain-language reason. There is no vessel identity, speed or course.

Tracks: the CSV has no track id, but every row repeats its route summary (PrimarySensorRoutePoints,
PrimarySensorRouteSpanKm). Rows sharing a summary whose count equals the declared number of route points are
one route; everything else is a single-point contact.

Detections are kept in atreides_detection (the Atreides section of the console) and also written to
vessel_track as non-cooperative MDA tracks (source_id "atreides") so fusion and the live map use them.

    python -m uavr.atreides import "MDA Sensor Mini Sample_APRIL_26.csv" [--shift-to-now]
    python -m uavr.atreides list
    python -m uavr.atreides delete BATCH_ID
"""

import argparse
import asyncio
import csv
import hashlib
import io
import sys
from collections import defaultdict
from datetime import UTC, datetime

from sqlalchemy import delete, insert, select
from sqlalchemy.ext.asyncio import AsyncSession

from .db.models import AtreidesBatch, AtreidesDetection, VesselTrack
from .db.session import dispose, sessionmaker

SOURCE_ID = "atreides"
ROLES = ("mobile_asset", "fixed_site", "ambiguous")
CONFIDENCES = ("high", "medium", "low")
CHUNK = 2000


class ParseError(ValueError):
    pass


def _int(v) -> int | None:
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


def _float(v) -> float | None:
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def _pick(v, allowed) -> str | None:
    return v if v in allowed else None


def combined_role(primary: str | None, source: str | None) -> str:
    """One role per detection: the primary view decides, a fixed-site source view settles ambiguous ones."""
    if primary == "mobile_asset":
        return "mobile_asset"
    if primary == "fixed_site" or source == "fixed_site":
        return "fixed_site"
    return "ambiguous"


def parse(text: str) -> tuple[list[dict], dict]:
    """CSV text -> detection dicts (without batch/track ids yet) and stats."""
    reader = csv.DictReader(io.StringIO(text.lstrip("﻿")))
    need = {"Latitude", "Longitude", "timestamp", "PrimarySensorRole"}
    if not reader.fieldnames or not need <= set(reader.fieldnames):
        raise ParseError(f"not an Atreides MDA export: needs columns {sorted(need)}")
    rows, dropped = [], 0
    for r in reader:
        lat, lon = _float(r.get("Latitude")), _float(r.get("Longitude"))
        try:
            at = datetime.fromisoformat((r.get("timestamp") or "").replace("Z", "+00:00"))
        except ValueError:
            at = None
        if (
            lat is None
            or lon is None
            or at is None
            or (lat == 0 and lon == 0)
            or not (-90 <= lat <= 90 and -180 <= lon <= 180)
        ):
            dropped += 1
            continue
        if at.tzinfo is None:
            at = at.replace(tzinfo=UTC)
        primary, source = _pick(r.get("PrimarySensorRole"), ROLES), _pick(r.get("SourceSensorRole"), ROLES)
        rows.append(
            {
                "at": at.astimezone(UTC),
                "lat": round(lat, 6),
                "lon": round(lon, 6),
                "role": combined_role(primary, source),
                "primary_role": primary,
                "primary_confidence": _pick(r.get("PrimarySensorRoleConfidence"), CONFIDENCES),
                "primary_reasoning": (r.get("PrimarySensorRoleReasoning") or None)
                and r["PrimarySensorRoleReasoning"][:255],
                "primary_route_points": _int(r.get("PrimarySensorRoutePoints")),
                "primary_route_span_km": _float(r.get("PrimarySensorRouteSpanKm")),
                "source_role": source,
                "source_confidence": _pick(r.get("SourceSensorRoleConfidence"), CONFIDENCES),
                "source_reasoning": (r.get("SourceSensorRoleReasoning") or None)
                and r["SourceSensorRoleReasoning"][:255],
                "source_route_points": _int(r.get("SourceSensorRoutePoints")),
                "source_route_span_km": _float(r.get("SourceSensorRouteSpanKm")),
                "content_type": (r.get("ContentType") or None) and r["ContentType"][:16],
                "file_len": _int(r.get("FileLen")),
            }
        )
    return rows, {"rows": len(rows) + dropped, "accepted": len(rows), "dropped": dropped}


def assign_tracks(rows: list[dict], prefix: str) -> int:
    """Set row["track_id"]; returns the number of multi-point routes."""
    groups: dict[tuple, list[dict]] = defaultdict(list)
    for r in rows:
        groups[(r["primary_route_points"], r["primary_route_span_km"])].append(r)
    routes = 0
    for (points, span), members in groups.items():
        if points and points > 1 and len(members) == points:
            routes += 1
            for r in members:
                r["track_id"] = f"{prefix}-R{points}-{span}"
        else:
            for r in members:
                h = hashlib.sha1(f"{r['lat']}|{r['lon']}|{r['at'].isoformat()}".encode()).hexdigest()[:10]
                r["track_id"] = f"{prefix}-P{h}"
    return routes


async def import_csv(
    session: AsyncSession, text: str, filename: str, via: str, by: str | None = None, shift_to_now: bool = False
) -> AtreidesBatch:
    """Parse and store one export. The caller commits."""
    rows, stats = parse(text)
    if not rows:
        raise ParseError("no valid detections in the file")
    rows.sort(key=lambda r: r["at"])
    shift = datetime.now(UTC) - rows[-1]["at"] if shift_to_now else None
    if shift:
        for r in rows:
            r["at"] = r["at"] + shift
    batch = AtreidesBatch(
        filename=filename[:255],
        rows=stats["rows"],
        accepted=stats["accepted"],
        dropped=stats["dropped"],
        tracks=0,
        first_at=rows[0]["at"],
        last_at=rows[-1]["at"],
        shifted_s=int(shift.total_seconds()) if shift else 0,
        received_via=via,
        received_by=by,
    )
    session.add(batch)
    await session.flush()
    assign_tracks(rows, f"ATR{batch.id}")
    batch.tracks = len({r["track_id"] for r in rows})
    for i in range(0, len(rows), CHUNK):
        chunk = rows[i : i + CHUNK]
        await session.execute(insert(AtreidesDetection), [{**r, "batch_id": batch.id} for r in chunk])
        await session.execute(
            insert(VesselTrack),
            [
                {
                    "source_kind": "mda",
                    "source_id": SOURCE_ID,
                    "track_id": r["track_id"],
                    "role": r["role"],
                    "role_confidence": r["primary_confidence"],
                    "at": r["at"],
                    "lat": r["lat"],
                    "lon": r["lon"],
                }
                for r in chunk
            ],
        )
    await session.refresh(batch)  # server-side created_at
    return batch


async def delete_batch(session: AsyncSession, batch_id: int) -> bool:
    batch = await session.get(AtreidesBatch, batch_id)
    if batch is None:
        return False
    await session.execute(
        delete(VesselTrack).where(
            VesselTrack.source_id == SOURCE_ID, VesselTrack.track_id.startswith(f"ATR{batch_id}-")
        )
    )
    await session.execute(delete(AtreidesDetection).where(AtreidesDetection.batch_id == batch_id))
    await session.delete(batch)
    return True


async def main(a: argparse.Namespace) -> int:
    try:
        async with sessionmaker()() as s:
            if a.cmd == "import":
                with open(a.csv, encoding="utf-8-sig") as fh:  # noqa: ASYNC230 - one-off CLI read
                    text = fh.read()
                b = await import_csv(s, text, a.csv.rsplit("/", 1)[-1], "cli", "cli", a.shift_to_now)
                await s.commit()
                print(
                    f"batch {b.id}: {b.accepted} detections ({b.dropped} dropped), {b.tracks} tracks, "
                    f"{b.first_at:%Y-%m-%d %H:%M} .. {b.last_at:%Y-%m-%d %H:%M} UTC"
                )
            elif a.cmd == "list":
                for b in (await s.execute(select(AtreidesBatch).order_by(AtreidesBatch.id))).scalars():
                    when = f"{b.created_at:%Y-%m-%d %H:%M}"
                    print(f"{b.id:4}  {when}  {b.accepted:6} det  {b.tracks:5} tracks  {b.filename}")
            elif a.cmd == "delete":
                if not await delete_batch(s, a.batch_id):
                    print("no such batch")
                    return 1
                await s.commit()
                print(f"deleted batch {a.batch_id}")
    except ParseError as e:
        print(f"error: {e}")
        return 1
    finally:
        await dispose()
    return 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    imp = sub.add_parser("import")
    imp.add_argument("csv")
    imp.add_argument(
        "--shift-to-now", action="store_true", help="move timestamps so the newest detection is now (demo)"
    )
    sub.add_parser("list")
    d = sub.add_parser("delete")
    d.add_argument("batch_id", type=int)
    sys.exit(asyncio.run(main(ap.parse_args())))
