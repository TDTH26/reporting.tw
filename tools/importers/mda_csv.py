"""Import an MDA sensor CSV export (e.g. "MDA Sensor Mini Sample_APRIL_26.csv") into the `ais` feed.

The export has no vessel identity (no MMSI/IMO/name) and no speed/course: each row is a timestamped
coordinate with a role classification (mobile_asset / fixed_site / ambiguous). Rows are therefore sent as
non-cooperative MDA tracks (`source_kind: mda`), never as identified AIS vessels.

Track reconstruction: the CSV has no track id, but every row repeats its route summary
(PrimarySensorRoutePoints, PrimarySensorRouteSpanKm). Rows sharing a summary whose count equals the declared
number of route points are one route; everything else is sent as a single-point contact.

    cd backend
    uv run python ../tools/importers/mda_csv.py "../MDA Sensor Mini Sample_APRIL_26.csv" --dry-run
    uv run python ../tools/importers/mda_csv.py "../MDA Sensor Mini Sample_APRIL_26.csv" --shift-to-now
"""

import argparse
import csv
import hashlib
import sys
from collections import defaultdict
from datetime import UTC, datetime

import httpx

BATCH = 1000


def load(path: str) -> tuple[list[dict], dict]:
    with open(path, newline="", encoding="utf-8-sig") as fh:
        rows = list(csv.DictReader(fh))
    stats = {"rows": len(rows), "invalid_position": 0, "routes": 0, "route_points": 0, "single_points": 0}
    good = []
    for r in rows:
        try:
            lat, lon = float(r["Latitude"]), float(r["Longitude"])
            t = datetime.fromisoformat(r["timestamp"])
        except (KeyError, ValueError):
            stats["invalid_position"] += 1
            continue
        if (lat == 0 and lon == 0) or not (-90 <= lat <= 90 and -180 <= lon <= 180):
            stats["invalid_position"] += 1
            continue
        good.append({**r, "_lat": lat, "_lon": lon, "_t": t})

    groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for r in good:
        groups[(r["PrimarySensorRoutePoints"], r["PrimarySensorRouteSpanKm"])].append(r)
    out = []
    for (points, span), members in groups.items():
        is_route = len(members) == int(points or 0) and int(points or 0) > 1
        if is_route:
            stats["routes"] += 1
            stats["route_points"] += len(members)
        for r in members:
            if is_route:
                tid = f"MDA-R{points}-{span}"
            else:
                stats["single_points"] += 1
                h = hashlib.sha1(f"{r['_lat']}{r['_lon']}{r['timestamp']}".encode()).hexdigest()[:10]
                tid = f"MDA-P-{h}"
            role = r["PrimarySensorRole"] if r["PrimarySensorRole"] in ("mobile_asset", "fixed_site") else "ambiguous"
            if r.get("SourceSensorRole") == "fixed_site" and r["PrimarySensorRole"] != "mobile_asset":
                role = "fixed_site"
            conf = r["PrimarySensorRoleConfidence"] if r["PrimarySensorRoleConfidence"] in ("high", "medium", "low") \
                else None
            out.append({"source_kind": "mda", "track_id": tid, "role": role, "role_confidence": conf,
                        "t": r["_t"], "lat": round(r["_lat"], 6), "lon": round(r["_lon"], 6)})
    out.sort(key=lambda v: v["t"])
    return out, stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv")
    ap.add_argument("--api", default="http://localhost:8480/api")
    ap.add_argument("--feed-key", default="dev-feed-key")
    ap.add_argument("--source-id", default="mda-sample")
    ap.add_argument("--shift-to-now", action="store_true",
                    help="move timestamps so the newest point is now (for demos; original times kept otherwise)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    vessels, stats = load(a.csv)
    if not vessels:
        print("nothing to import", stats)
        return 1
    shift = datetime.now(UTC) - vessels[-1]["t"] if a.shift_to_now else None
    for v in vessels:
        t = v["t"] + shift if shift else v["t"]
        v["t"] = t.astimezone(UTC).isoformat().replace("+00:00", "Z")
        if v["role_confidence"] is None:
            del v["role_confidence"]
    print(f"{stats['rows']} rows: {stats['invalid_position']} invalid dropped, {stats['routes']} routes "
          f"({stats['route_points']} points), {stats['single_points']} single-point contacts; "
          f"{vessels[0]['t']} .. {vessels[-1]['t']}")
    if a.dry_run:
        return 0
    with httpx.Client(timeout=120) as c:
        sent = 0
        for i in range(0, len(vessels), BATCH):
            chunk = vessels[i : i + BATCH]
            body = {"schema": "uavr.feed.ais/1", "source_id": a.source_id,
                    "sent_at": datetime.now(UTC).isoformat().replace("+00:00", "Z"), "vessels": chunk}
            r = c.post(f"{a.api}/v1/ingest/ais", json=body, headers={"X-Feed-Key": a.feed_key})
            if r.status_code != 200:
                print("failed:", r.status_code, r.text[:500])
                return 1
            sent += len(chunk)
        print(f"imported {sent} points")
    return 0


if __name__ == "__main__":
    sys.exit(main())
