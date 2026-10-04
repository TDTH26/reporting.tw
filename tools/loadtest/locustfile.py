"""Load tests: genuine report surges vs. spam floods disguised as surges.

    cd backend && uv run locust -f ../tools/loadtest/locustfile.py --host http://localhost:8480/api
    # headless, 300 genuine informants + 30 spammers for 3 minutes:
    uv run locust -f ../tools/loadtest/locustfile.py --host http://localhost:8480/api \
        --headless -u 330 -r 50 -t 3m GenuineInformant Spammer

What to look at afterwards (psql):
  * genuine traffic collapses into a handful of incidents (one per simulated drone);
  * spam observations carry spam_score >= 0.4 and many requests end in 429;
  * p95 of POST /v1/reports stays low (metadata path only; media is not uploaded here).
"""

import math
import random
import uuid
from datetime import UTC, datetime

from locust import HttpUser, between, task

R = 6_371_008.8
# A few drones over busy places; genuine informants crowd around them.
DRONES = [(25.0330, 121.5654), (25.0478, 121.5170), (22.6273, 120.3014), (24.1477, 120.6736)]


def _dest(lat, lon, bearing, dist):
    b = math.radians(bearing)
    return (lat + math.degrees(dist * math.cos(b) / R),
            lon + math.degrees(dist * math.sin(b) / (R * math.cos(math.radians(lat)))))


def _bearing(a, b):
    x = math.radians(b[1] - a[1]) * math.cos(math.radians(a[0]))
    y = math.radians(b[0] - a[0])
    return (math.degrees(math.atan2(x, y)) + 360) % 360


def _body(device, observer, bearing=None, attestation="dev-pass"):
    return {
        "client_report_id": str(uuid.uuid4()),
        "platform": "android",
        "app_version": "locust",
        "language": "zh-TW",
        "device_id": device,
        "observed_at": datetime.now(UTC).isoformat(),
        "observer": {"lat": observer[0], "lon": observer[1], "accuracy_m": 8},
        "bearing_deg": bearing,
        "elevation_deg": 15 if bearing is not None else None,
        "attestation_token": attestation,
    }


class GenuineInformant(HttpUser):
    """Many independent devices, each reporting once or twice about a real drone nearby."""

    wait_time = between(5, 40)

    def on_start(self):
        self.device = f"lt-{uuid.uuid4().hex}"
        self.drone = random.choice(DRONES)

    @task
    def report(self):
        ob = _dest(*self.drone, random.uniform(0, 360), random.uniform(200, 900))
        b = (_bearing(ob, self.drone) + random.uniform(-6, 6)) % 360
        self.client.post("/v1/reports", json=_body(self.device, ob, b), name="POST /v1/reports (genuine)")


class Spammer(HttpUser):
    """Few devices, no attestation, no bearing, random places all over Taiwan, as fast as allowed."""

    wait_time = between(0.2, 1.0)

    def on_start(self):
        self.device = f"spam-{uuid.uuid4().hex[:6]}"

    @task
    def report(self):
        spot = (random.uniform(22.5, 25.2), random.uniform(120.2, 121.7))
        with self.client.post("/v1/reports", json=_body(self.device, spot, None, "dev-fail"),
                              name="POST /v1/reports (spam)", catch_response=True) as r:
            if r.status_code == 429:
                r.success()  # rate limiting is the expected outcome
