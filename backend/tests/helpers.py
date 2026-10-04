import random
import uuid
from datetime import UTC, datetime

from uavr.domain.geo import destination, to_enu

XINYI = (25.0330, 121.5654)  # residential demo zone, Taipei
SONGSHAN = (25.0694, 121.5525)  # airport zone
HSINCHU_MIL = (24.8180, 120.9393)  # demo military zone
KINMEN = (24.45, 118.35)


def bearing_to(frm, to) -> float:
    import math

    v = to_enu(frm[0], frm[1], to[0], to[1])
    return (math.degrees(math.atan2(v[0], v[1])) + 360) % 360


def report(
    drone=XINYI,
    *,
    observer_dist=400,
    observer_bearing=None,
    platform="android",
    device=None,
    attestation="dev-pass",
    media=None,
    jitter=0.0,
    elevation=12.0,
    remote_id=None,
    **kw,
) -> dict:
    ob = observer_bearing if observer_bearing is not None else random.uniform(0, 360)
    olat, olon = destination(drone[0], drone[1], ob, observer_dist)
    b = (bearing_to((olat, olon), drone) + random.uniform(-jitter, jitter)) % 360
    body = {
        "client_report_id": str(uuid.uuid4()),
        "platform": platform,
        "app_version": "1.0.0",
        "language": kw.pop("language", "zh-TW"),
        "device_id": device or f"dev-{uuid.uuid4().hex}",
        "observed_at": datetime.now(UTC).isoformat(),
        "observer": {"lat": olat, "lon": olon, "accuracy_m": 8},
        "bearing_deg": b if platform == "android" else None,
        "elevation_deg": elevation if platform == "android" else None,
        "remote_id": remote_id or [],
        "media": media or [],
        "attestation_token": attestation if platform == "android" else None,
        "description": kw.pop("description", None),
    }
    body.update(kw)
    return body
