"""Small-area geodesy helpers (local East-North-Up tangent plane, WGS84)."""

import math

import numpy as np

EARTH_R = 6_371_008.8


def to_enu(lat0: float, lon0: float, lat: float, lon: float) -> np.ndarray:
    """Equirectangular projection around (lat0, lon0); accurate to <0.1% within ~20 km."""
    x = math.radians(lon - lon0) * EARTH_R * math.cos(math.radians(lat0))
    y = math.radians(lat - lat0) * EARTH_R
    return np.array([x, y])


def from_enu(lat0: float, lon0: float, xy: np.ndarray) -> tuple[float, float]:
    lat = lat0 + math.degrees(xy[1] / EARTH_R)
    lon = lon0 + math.degrees(xy[0] / (EARTH_R * math.cos(math.radians(lat0))))
    return lat, lon


def bearing_unit(bearing_deg: float) -> np.ndarray:
    """Compass bearing (0 = north, clockwise) to an ENU unit vector."""
    b = math.radians(bearing_deg)
    return np.array([math.sin(b), math.cos(b)])


def destination(lat: float, lon: float, bearing_deg: float, distance_m: float) -> tuple[float, float]:
    return from_enu(lat, lon, bearing_unit(bearing_deg) * distance_m)


def distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_R * math.asin(math.sqrt(a))


def cell_key(lat: float, lon: float, size_deg: float = 0.05) -> tuple[int, int]:
    return (math.floor(lat / size_deg), math.floor(lon / size_deg))


def neighbourhood_lock_keys(lat: float, lon: float, size_deg: float = 0.05) -> list[int]:
    """Advisory-lock keys for the 3x3 grid cells around a point, sorted to avoid deadlocks.

    A cell is 0.05 deg (~5.5 km), larger than the clustering radius, so two observations
    that could join the same incident always share at least one locked cell.
    """
    ci, cj = cell_key(lat, lon, size_deg)
    keys = {_pack(ci + di, cj + dj) for di in (-1, 0, 1) for dj in (-1, 0, 1)}
    return sorted(keys)


def _pack(i: int, j: int) -> int:
    # Namespace 0x55 ("U") in the top byte keeps these clear of other advisory locks.
    return (0x55 << 56) | ((i & 0xFFFFFFF) << 28) | (j & 0xFFFFFFF)
