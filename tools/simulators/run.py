"""Simulated external feeds and informant traffic for the dev stack.

Every adapter is built and tested against these before its real agreement/hardware arrives.

    cd backend && uv run python ../tools/simulators/run.py --scenario all
    uv run python ../tools/simulators/run.py --scenario surge --reports 300 --seconds 120

Scenarios:
  caa      registry + permit sync (one permitted drone, one unregistered)
  weather  surface observations around Taipei / Taoyuan
  cctv     a few city cameras
  sensor   RF sensor track of a drone approaching Taoyuan airport (with serial + pilot position)
  adsb     an airliner on approach to TPE passing the sensor drone -> Critical escalation
  permitted  Remote ID broadcast from the permitted drone inside its permit area -> Likely authorized
  surge    genuine surge: many independent informants around one drone in Xinyi (one incident)
  spam     spam flood disguised as a surge: few devices, failed attestation, random places
  all      everything above in a sensible order
"""

import argparse
import asyncio
import math
import random
import time
import uuid
from datetime import UTC, datetime, timedelta

import httpx

TPE_AIRPORT = (25.0777, 121.2328)
XINYI = (25.0330, 121.5654)
PERMIT_AREA = (25.0300, 121.5357)  # Da'an park (yellow zone)
R = 6_371_008.8


def now(dt: float = 0) -> str:
    return (datetime.now(UTC) + timedelta(seconds=dt)).isoformat().replace("+00:00", "Z")


def dest(lat: float, lon: float, bearing: float, dist: float) -> tuple[float, float]:
    b = math.radians(bearing)
    dlat = dist * math.cos(b) / R
    dlon = dist * math.sin(b) / (R * math.cos(math.radians(lat)))
    return lat + math.degrees(dlat), lon + math.degrees(dlon)


def bearing_to(a: tuple[float, float], b: tuple[float, float]) -> float:
    x = math.radians(b[1] - a[1]) * math.cos(math.radians(a[0]))
    y = math.radians(b[0] - a[0])
    return (math.degrees(math.atan2(x, y)) + 360) % 360


class Sim:
    def __init__(self, api: str, feed_key: str, verbose: bool):
        self.api = api.rstrip("/")
        self.c = httpx.AsyncClient(timeout=30)
        self.feed = {"X-Feed-Key": feed_key}
        self.verbose = verbose

    async def ingest(self, feed: str, payload: dict) -> dict:
        r = await self.c.post(f"{self.api}/v1/ingest/{feed}", json=payload, headers=self.feed)
        if r.status_code != 200:
            raise SystemExit(f"{feed}: {r.status_code} {r.text[:300]}")
        return r.json()

    def env(self, feed: str, source: str, key: str, items: list) -> dict:
        return {"schema": f"uavr.feed.{feed}/1", "source_id": source, "sent_at": now(), key: items}

    async def report(self, drone, *, dist=400, device=None, attestation="dev-pass", jitter=5.0, remote_id=None,
                     platform="android", spot=None) -> httpx.Response:
        ob = spot or dest(*drone, random.uniform(0, 360), dist)
        body = {
            "client_report_id": str(uuid.uuid4()),
            "platform": platform,
            "app_version": "sim",
            "language": random.choice(["zh-TW", "zh-TW", "zh-TW", "en", "vi", "id", "th", "fil"]),
            "device_id": device or f"sim-{uuid.uuid4().hex}",
            "observed_at": now(),
            "observer": {"lat": ob[0], "lon": ob[1], "accuracy_m": random.uniform(4, 15)},
            "remote_id": remote_id or [],
            "attestation_token": attestation if platform == "android" else None,
        }
        if platform == "android" and spot is None:
            body["bearing_deg"] = (bearing_to(ob, drone) + random.uniform(-jitter, jitter)) % 360
            body["elevation_deg"] = math.degrees(math.atan2(90, dist)) + random.uniform(-3, 3)
        return await self.c.post(f"{self.api}/v1/reports", json=body)

    # ------------------------------------------------------------------ scenarios

    async def caa(self):
        reg = [
            {"serial": "SIM-PERMITTED-001", "registration_no": "TW-UAV-0100001", "status": "active",
             "owner": {"name": "大安空拍有限公司", "owner_ref": "CAA-OWN-10001", "kind": "organisation"},
             "model": "Mavic 3 Enterprise", "manufacturer": "DJI", "mtow_g": 915},
            {"serial": "SIM-ROGUE-777", "registration_no": "TW-UAV-0100777", "status": "suspended",
             "owner": {"name": "陳小明", "owner_ref": "CAA-OWN-20777", "kind": "person"},
             "model": "Mini 4 Pro", "manufacturer": "DJI", "mtow_g": 249},
        ]
        lat, lon = PERMIT_AREA
        d = 0.006
        permit = {"permit_no": "SIM-P-2026-001", "serials": ["SIM-PERMITTED-001"], "valid_from": now(-3600),
                  "valid_to": now(6 * 3600), "max_alt_m": 120, "operator_name": "大安空拍有限公司",
                  "area": {"type": "Polygon", "coordinates": [[[lon - d, lat - d], [lon + d, lat - d], [lon + d, lat + d],
                                                               [lon - d, lat + d], [lon - d, lat - d]]]}}
        print("caa:", await self.ingest("registry", self.env("registry", "caa-registry-sim", "records", reg)),
              await self.ingest("permit", self.env("permit", "caa-permits-sim", "permits", [permit])))

    async def weather(self):
        obs = [
            {"station_id": "466920", "t": now(-300), "lat": 25.0377, "lon": 121.5149, "visibility_m": 9000,
             "wind_speed_mps": 3.1, "wind_dir_deg": 70},
            {"station_id": "467050", "t": now(-300), "lat": 25.0697, "lon": 121.2181, "visibility_m": 6000,
             "wind_speed_mps": 6.4, "wind_dir_deg": 40},
        ]
        print("weather:", await self.ingest("weather", self.env("weather", "cwa-sim", "observations", obs)))

    async def cctv(self):
        cams = [
            {"camera_id": f"SIM-CAM-{i:03d}", "name": n, "lat": la, "lon": lo,
             "stream_url": f"https://cctv.example.gov.tw/live/SIM-CAM-{i:03d}.m3u8", "owner": "臺北市政府警察局"}
            for i, (n, la, lo) in enumerate([
                ("信義路五段 / 松智路口", 25.0332, 121.5660), ("松高路 / 松仁路口", 25.0381, 121.5683),
                ("基隆路一段 / 信義路口", 25.0335, 121.5583), ("大安森林公園 新生南路側", 25.0299, 121.5330),
            ])
        ]
        print("cctv:", await self.ingest("cctv", self.env("cctv", "tpe-cctv-sim", "cameras", cams)))

    async def sensor(self, updates: int = 15, interval: float = 2.0):
        """A drone crossing towards the TPE approach path, tracked by an RF sensor."""
        start = dest(*TPE_AIRPORT, 120, 7000)
        sensor_pos = dest(*TPE_AIRPORT, 150, 4000)
        heading = bearing_to(start, TPE_AIRPORT)
        for i in range(updates):
            p0 = dest(*start, heading, i * 120)
            p1 = dest(*start, heading, i * 120 + 60)
            tr = {"sensor_id": "SIM-TY-RF-01", "sensor_kind": "rf", "track_id": "SIM-T-1", "status": "active",
                  "sensor_position": {"lat": sensor_pos[0], "lon": sensor_pos[1]},
                  "points": [{"t": now(-1), "lat": p0[0], "lon": p0[1], "alt_m": 110 + i, "alt_ref": "agl",
                              "speed_mps": 30, "heading_deg": heading},
                             {"t": now(), "lat": p1[0], "lon": p1[1], "alt_m": 112 + i, "alt_ref": "agl",
                              "speed_mps": 30, "heading_deg": heading}],
                  "classification": {"target_type": "multirotor", "confidence": 0.9},
                  "rf": {"frequency_mhz": 5745, "protocol": "OcuSync", "serial": "SIM-ROGUE-777",
                         "pilot_position": {"lat": start[0] - 0.004, "lon": start[1] + 0.003}}}
            res = await self.ingest("sensor-track", self.env("sensor-track", "vendor-sim", "tracks", [tr]))
            if self.verbose or i == 0:
                print(f"sensor update {i + 1}/{updates}:", res)
            await asyncio.sleep(interval)
        print("sensor: done")

    async def adsb(self, updates: int = 10, interval: float = 2.0):
        """EVA flight on final approach passing near the RF-tracked drone."""
        drone_area = dest(*TPE_AIRPORT, 120, 5500)
        start = dest(*drone_area, 120, 6000)
        hdg = bearing_to(start, TPE_AIRPORT)
        esc = 0
        for i in range(updates):
            p = dest(*start, hdg, i * 600)
            st = [{"icao24": "8991a2", "callsign": "EVA0012", "t": now(), "lat": p[0], "lon": p[1],
                   "alt_geo_m": max(300, 900 - i * 60), "ground_speed_mps": 75, "track_deg": hdg, "on_ground": False}]
            res = await self.ingest("adsb", self.env("adsb", "adsb-sim", "states", st))
            esc += res.get("incidents_escalated", 0)
            await asyncio.sleep(interval)
        print(f"adsb: done, incidents escalated: {esc}")

    async def permitted(self):
        rid = [{"transport": "bt5", "received_at": now(), "uas_id": "SIM-PERMITTED-001", "id_type": "serial",
                "ua_type": "helicopter_or_multirotor", "lat": PERMIT_AREA[0], "lon": PERMIT_AREA[1], "height_m": 80,
                "operator_lat": PERMIT_AREA[0] - 0.001, "operator_lon": PERMIT_AREA[1] - 0.001}]
        r = await self.report(PERMIT_AREA, remote_id=rid)
        print("permitted:", r.status_code, r.json().get("case_number"))

    async def surge(self, reports: int = 150, seconds: float = 60):
        t0 = time.monotonic()
        cases: dict[str, int] = {}
        sem = asyncio.Semaphore(25)

        async def one(i: int):
            await asyncio.sleep(random.uniform(0, seconds))
            async with sem:
                r = await self.report(XINYI, dist=random.uniform(250, 900))
            if r.status_code == 201:
                n = r.json()["case_number"]
                cases[n] = cases.get(n, 0) + 1

        await asyncio.gather(*(one(i) for i in range(reports)))
        print(f"surge: {reports} reports in {time.monotonic() - t0:.1f}s -> cases {cases}")

    async def spam(self, reports: int = 120, devices: int = 4):
        devs = [f"spam-{uuid.uuid4().hex[:8]}" for _ in range(devices)]
        codes: dict[int, int] = {}
        for _ in range(reports):
            spot = (random.uniform(22.6, 25.2), random.uniform(120.2, 121.6))
            r = await self.report(spot, device=random.choice(devs), attestation="dev-fail", spot=spot)
            codes[r.status_code] = codes.get(r.status_code, 0) + 1
        print(f"spam: status codes {codes} (429 = device rate limit; accepted ones carry a high spam score)")


async def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--api", default="http://localhost:8480/api")
    ap.add_argument("--feed-key", default="dev-feed-key")
    ap.add_argument("--scenario", default="all",
                    choices=["all", "caa", "weather", "cctv", "sensor", "adsb", "permitted", "surge", "spam"])
    ap.add_argument("--reports", type=int, default=150)
    ap.add_argument("--seconds", type=float, default=60)
    ap.add_argument("-v", "--verbose", action="store_true")
    a = ap.parse_args()
    s = Sim(a.api, a.feed_key, a.verbose)
    if a.scenario == "all":
        await s.caa()
        await s.weather()
        await s.cctv()
        await s.permitted()
        await asyncio.gather(s.sensor(), s.adsb())
        await s.surge(a.reports, a.seconds)
        await s.spam()
    elif a.scenario == "surge":
        await s.surge(a.reports, a.seconds)
    else:
        await getattr(s, a.scenario)()
    await s.c.aclose()


if __name__ == "__main__":
    asyncio.run(main())
