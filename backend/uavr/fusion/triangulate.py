"""Bearing-line triangulation in a local tangent plane."""

import math
from dataclasses import dataclass

import numpy as np

from ..domain.geo import bearing_unit, from_enu, to_enu


@dataclass(frozen=True)
class BearingLine:
    lat: float
    lon: float
    bearing_deg: float
    elevation_deg: float | None = None
    weight: float = 1.0
    bearing_sigma_deg: float = 10.0  # typical phone compass error


@dataclass(frozen=True)
class Fix:
    lat: float
    lon: float
    error_m: float
    altitude_m: float | None
    used: int


MIN_ANGLE_DEG = 12.0  # lines nearly parallel give no usable intersection
MAX_RANGE_M = 8000.0


def triangulate(lines: list[BearingLine]) -> Fix | None:
    """Weighted least-squares point closest to all bearing rays.

    Minimises sum_i w_i * |(I - d_i d_i^T)(x - p_i)|^2. Returns None when the geometry is too
    weak (fewer than two lines, near-parallel lines, or a solution behind the observers).
    """
    if len(lines) < 2:
        return None
    lat0 = sum(l.lat for l in lines) / len(lines)
    lon0 = sum(l.lon for l in lines) / len(lines)
    P = [to_enu(lat0, lon0, l.lat, l.lon) for l in lines]
    D = [bearing_unit(l.bearing_deg) for l in lines]
    W = [max(l.weight, 1e-3) / (math.radians(l.bearing_sigma_deg) ** 2) for l in lines]

    if _max_pairwise_angle(D) < MIN_ANGLE_DEG:
        return None

    A = np.zeros((2, 2))
    b = np.zeros(2)
    for p, d, w in zip(P, D, W, strict=True):
        M = np.eye(2) - np.outer(d, d)
        A += w * M
        b += w * M @ p
    if np.linalg.cond(A) > 1e6:
        return None
    x = np.linalg.solve(A, b)

    # Keep only rays that actually point at the solution and are within plausible range.
    ranges = [float(np.dot(x - p, d)) for p, d in zip(P, D, strict=True)]
    if sum(1 for r in ranges if 0 < r < MAX_RANGE_M) < 2:
        return None

    perp = [float(np.linalg.norm((np.eye(2) - np.outer(d, d)) @ (x - p))) for p, d in zip(P, D, strict=True)]
    # Error: RMS miss distance, floored by the angular uncertainty at the mean range.
    mean_range = float(np.mean([max(r, 1.0) for r in ranges]))
    angular = mean_range * math.radians(min(l.bearing_sigma_deg for l in lines)) / math.sqrt(len(lines))
    error = max(float(np.sqrt(np.mean(np.square(perp)))), angular)

    alts = [
        r * math.tan(math.radians(l.elevation_deg)) + 1.5
        for r, l in zip(ranges, lines, strict=True)
        if l.elevation_deg is not None and 0 < l.elevation_deg < 89 and r > 0
    ]
    lat, lon = from_enu(lat0, lon0, x)
    return Fix(lat, lon, error, float(np.median(alts)) if alts else None, len(lines))


def project_single(line: BearingLine, assumed_alt_m: float | None, default_range_m: float) -> Fix:
    """One bearing line: place the drone along the ray at a range from elevation + assumed altitude."""
    rng = default_range_m
    alt = assumed_alt_m
    if line.elevation_deg is not None and 3 < line.elevation_deg < 85:
        alt = assumed_alt_m if assumed_alt_m is not None else 80.0
        rng = min(max((alt - 1.5) / math.tan(math.radians(line.elevation_deg)), 20.0), 3000.0)
    xy = bearing_unit(line.bearing_deg) * rng
    lat, lon = from_enu(line.lat, line.lon, xy)
    return Fix(lat, lon, max(rng * 0.6, 150.0), alt, 1)


def _max_pairwise_angle(D: list[np.ndarray]) -> float:
    best = 0.0
    for i in range(len(D)):
        for j in range(i + 1, len(D)):
            c = abs(float(np.clip(np.dot(D[i], D[j]), -1, 1)))
            best = max(best, math.degrees(math.acos(c)))
    return best
