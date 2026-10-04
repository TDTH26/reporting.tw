import math

import pytest

from uavr.domain.enums import Authorization, CaseAction, CaseState, Severity
from uavr.domain.geo import destination, distance_m
from uavr.domain.state import InvalidTransition, next_state
from uavr.fusion import severity as sev
from uavr.fusion.triangulate import BearingLine, project_single, triangulate
from uavr.security import crypto

from .helpers import XINYI, bearing_to


def test_triangulate_two_lines_hits_target():
    a = destination(*XINYI, 200, 500)
    b = destination(*XINYI, 300, 700)
    fix = triangulate(
        [
            BearingLine(*a, bearing_to(a, XINYI), elevation_deg=math.degrees(math.atan2(100, 500))),
            BearingLine(*b, bearing_to(b, XINYI), elevation_deg=math.degrees(math.atan2(100, 700))),
        ]
    )
    assert fix is not None
    assert distance_m(fix.lat, fix.lon, *XINYI) < 5
    assert fix.altitude_m == pytest.approx(101.5, abs=3)


def test_triangulate_noisy_many_lines():
    import random

    random.seed(4)
    lines = []
    for i in range(12):
        p = destination(*XINYI, i * 30, 400 + i * 20)
        lines.append(BearingLine(*p, (bearing_to(p, XINYI) + random.uniform(-6, 6)) % 360))
    fix = triangulate(lines)
    assert fix and distance_m(fix.lat, fix.lon, *XINYI) < 60


def test_triangulate_rejects_parallel_and_single():
    a = destination(*XINYI, 180, 500)
    b = destination(*XINYI, 180, 900)
    assert triangulate([BearingLine(*a, 0), BearingLine(*b, 0)]) is None
    assert triangulate([BearingLine(*a, 0)]) is None


def test_triangulate_rejects_solution_behind_observers():
    a = destination(*XINYI, 90, 500)
    b = destination(*XINYI, 0, 500)
    # Both look away from the drone.
    assert triangulate([BearingLine(*a, 90), BearingLine(*b, 0)]) is None


def test_project_single_uses_elevation():
    o = destination(*XINYI, 180, 300)
    f = project_single(BearingLine(*o, 0, elevation_deg=math.degrees(math.atan2(80, 300))), 81.5, 300)
    assert distance_m(f.lat, f.lon, *XINYI) < 10


def _inp(**kw):
    base = dict(
        zone_types=set(),
        authorization=Authorization.unknown,
        sensor_confirmed=False,
        has_remote_id=False,
        adsb_nearby=False,
        only_web_reports=False,
        single_report=False,
    )
    base.update(kw)
    return sev.SeverityInput(**base)


@pytest.mark.parametrize(
    "kw,expected",
    [
        (dict(), Severity.low),
        (dict(adsb_nearby=True), Severity.critical),
        (dict(zone_types={"airport"}), Severity.critical),
        (dict(zone_types={"outlying_islands_strict"}), Severity.critical),
        (dict(zone_types={"red"}), Severity.medium),
        (dict(zone_types={"red"}, sensor_confirmed=True), Severity.critical),
        (dict(zone_types={"yellow"}), Severity.medium),
        (dict(zone_types={"yellow"}, authorization=Authorization.likely_authorized, has_remote_id=True), Severity.low),
        (
            dict(zone_types={"airport"}, authorization=Authorization.likely_authorized, adsb_nearby=True),
            Severity.critical,
        ),
        (dict(zone_types={"residential"}, hovering=True), Severity.medium),
        (dict(zone_types={"airport"}, only_web_reports=True, single_report=True), Severity.medium),
    ],
)
def test_severity_rules(kw, expected):
    assert sev.compute(_inp(**kw)).severity == expected


def test_state_machine():
    assert next_state(CaseState.new, CaseAction.acknowledged) == CaseState.acknowledged
    assert next_state(CaseState.investigating, CaseAction.transferred) == CaseState.new
    with pytest.raises(InvalidTransition):
        next_state(CaseState.new, CaseAction.resolved)
    with pytest.raises(InvalidTransition):
        next_state(CaseState.closed, CaseAction.acknowledged)


def test_envelope_crypto_roundtrip():
    blob = crypto.encrypt("defense note", b"aad")
    assert crypto.decrypt(blob, b"aad") == "defense note"
    with pytest.raises(Exception):
        crypto.decrypt(blob, b"other")


def test_request_hash_matches_dart_client():
    """Same vector as app/packages/uavr_api/test/api_test.dart."""
    from datetime import UTC, datetime

    from uavr.api.report_schemas import ReportIn

    r = ReportIn(
        client_report_id="00000000-0000-0000-0000-000000000001",
        platform="android",
        app_version="1",
        language="en",
        device_id="device-12345",
        observed_at=datetime(2026, 10, 2, 8, 0, 0, 123000, tzinfo=UTC),
        observer={"lat": 25.0330001, "lon": 121.5654},
        media=[
            {
                "slot": "b",
                "kind": "photo",
                "mime_type": "image/jpeg",
                "sha256": "b" * 64,
                "size_bytes": 1,
                "captured_at": "2026-01-01T00:00:00Z",
            },
            {
                "slot": "a",
                "kind": "audio",
                "mime_type": "audio/aac",
                "sha256": "a" * 64,
                "size_bytes": 1,
                "captured_at": "2026-01-01T00:00:00Z",
            },
        ],
    )
    import hashlib

    from uavr.api.reports import request_hash

    canon = (
        f"uavr-report-v1|00000000-0000-0000-0000-000000000001|1790928000123|25.033000|121.565400|{'a' * 64},{'b' * 64}"
    )
    assert request_hash(r) == hashlib.sha256(canon.encode()).hexdigest()


def test_client_ip_header(monkeypatch):
    from types import SimpleNamespace

    from uavr.config import get_settings
    from uavr.security.hashing import client_ip

    req = SimpleNamespace(headers={"CF-Connecting-IP": "203.0.113.7"}, client=SimpleNamespace(host="172.70.1.1"))
    assert client_ip(req) == "172.70.1.1"  # header ignored unless configured
    monkeypatch.setattr(get_settings(), "client_ip_header", "CF-Connecting-IP")
    assert client_ip(req) == "203.0.113.7"
    assert client_ip(SimpleNamespace(headers={}, client=SimpleNamespace(host="198.51.100.2"))) == "198.51.100.2"
