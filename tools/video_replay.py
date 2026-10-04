"""Replay a recorded video through a camera feed: frames -> AI detection -> tracks and behaviour alerts.

    uv run --project backend python tools/video_replay.py drone.mp4 --feed DEMO-CAM-1 \
        --lat 24.8180 --lon 120.9393 --bearing 90 --fov 60 --fps 0.5 \
        --zone 0.4,0.3,0.7,0.3,0.7,0.7,0.4,0.7

Needs ffmpeg locally and an admin login (UAVR_USER / UAVR_PASSWORD, prompted if unset). Frames are timestamped so the
video ends "now"; the worker processes them in order. Watch the result in the console (camera tracks) or with
GET /v1/agency/video-feeds/<feed>/tracks.
"""

import argparse
import getpass
import os
import subprocess
import sys
import tempfile
from datetime import UTC, datetime, timedelta
from pathlib import Path

import httpx


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("video")
    ap.add_argument("--api", default="https://api.reporting.tw")
    ap.add_argument("--feed", required=True, help="camera id, created or updated")
    ap.add_argument("--name", help="camera name (default: the id)")
    ap.add_argument("--lat", type=float, required=True)
    ap.add_argument("--lon", type=float, required=True)
    ap.add_argument("--bearing", type=float, help="optical axis in degrees")
    ap.add_argument("--fov", type=float, default=60)
    ap.add_argument("--domains", default="aerial", help="comma list: aerial,surface,...")
    ap.add_argument("--fps", type=float, default=0.5, help="frames per second to sample (the model is slow)")
    ap.add_argument("--max-frames", type=int, default=40)
    ap.add_argument("--zone", help="watch area polygon in image coordinates: x1,y1,x2,y2,... (0..1)")
    a = ap.parse_args()

    user = os.environ.get("UAVR_USER") or input("admin user: ")
    password = os.environ.get("UAVR_PASSWORD") or getpass.getpass("password: ")
    with httpx.Client(base_url=a.api, timeout=60) as c:
        r = c.post("/v1/auth/login", json={"username": user, "password": password, "client": "console"})
        r.raise_for_status()
        c.headers["Authorization"] = f"Bearer {r.json()['access_token']}"

        zone = None
        if a.zone:
            v = [float(x) for x in a.zone.split(",")]
            zone = [[v[i], v[i + 1]] for i in range(0, len(v) - 1, 2)]
        feed = {
            "id": a.feed, "name": a.name or a.feed, "lat": a.lat, "lon": a.lon, "bearing_deg": a.bearing,
            "fov_deg": a.fov, "domains": a.domains.split(","), "alert_zone": zone,
            "sample_interval_s": max(1, int(round(1 / a.fps))),
        }
        r = c.put(f"/v1/admin/video-feeds/{a.feed}", json=feed)
        r.raise_for_status()

        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run(
                ["ffmpeg", "-loglevel", "error", "-i", a.video, "-vf", f"fps={a.fps},scale='min(1280,iw)':-2",
                 "-frames:v", str(a.max_frames), "-q:v", "3", f"{tmp}/f%04d.jpg"],
                check=True,
            )
            frames = sorted(Path(tmp).glob("f*.jpg"))
            if not frames:
                print("no frames extracted")
                return 1
            step = timedelta(seconds=1 / a.fps)
            start = datetime.now(UTC) - step * (len(frames) - 1)
            for i, f in enumerate(frames):
                at = (start + step * i).isoformat()
                r = c.post(f"/v1/admin/video-feeds/{a.feed}/frames", data={"captured_at": at},
                           files={"file": (f.name, f.read_bytes(), "image/jpeg")})
                r.raise_for_status()
            print(f"queued {len(frames)} frames for {a.feed}; the worker detects and tracks them in order")
    return 0


if __name__ == "__main__":
    sys.exit(main())
