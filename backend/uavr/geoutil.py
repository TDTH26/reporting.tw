"""Geometry helpers. Coordinates are stored as plain lat/lon; GeoJSON (lon, lat) is used for polygons and in the API.

Distances use a local equirectangular projection around the point of interest, accurate to well under 1 % within the
tens of kilometres this system cares about.
"""

import math

from shapely.geometry import LineString, MultiPolygon, Point, mapping, shape
from shapely.ops import transform

from .domain.geo import EARTH_R, distance_m

M_PER_DEG_LAT = math.pi * EARTH_R / 180


def latlon(lat: float | None, lon: float | None) -> dict | None:
    return None if lat is None or lon is None else {"lat": lat, "lon": lon}


def line_geojson(coords_latlon: list | None) -> dict | None:
    """[[lat, lon(, alt)], ...] -> GeoJSON LineString."""
    if not coords_latlon or len(coords_latlon) < 2:
        return None
    return {"type": "LineString", "coordinates": [[c[1], c[0]] for c in coords_latlon]}


def bearing_line(lat: float | None, lon: float | None, bearing: float | None, length_m: float = 3000) -> dict | None:
    if lat is None or lon is None or bearing is None:
        return None
    from .domain.geo import destination

    lat2, lon2 = destination(lat, lon, bearing, length_m)
    return {"type": "LineString", "coordinates": [[lon, lat], [lon2, lat2]]}


def bbox_deg(lat: float, radius_m: float) -> tuple[float, float]:
    """(dlat, dlon) half-sizes of a box enclosing a circle of radius_m."""
    dlat = radius_m / M_PER_DEG_LAT
    dlon = radius_m / (M_PER_DEG_LAT * max(math.cos(math.radians(lat)), 0.01))
    return dlat, dlon


def normalize_multipolygon(gj: dict) -> dict:
    s = shape(gj)
    if s.geom_type == "Polygon":
        s = MultiPolygon([s])
    if s.geom_type != "MultiPolygon":
        raise ValueError("expected Polygon or MultiPolygon")
    if not s.is_valid:
        raise ValueError("polygon is not valid (self-intersecting?)")
    return mapping(s)


def bounds(gj: dict) -> tuple[float, float, float, float]:
    """(min_lat, min_lon, max_lat, max_lon)."""
    minx, miny, maxx, maxy = shape(gj).bounds
    return miny, minx, maxy, maxx


def distance_to_geometry_m(gj: dict, lat: float, lon: float) -> float:
    """Metres from a point to a GeoJSON geometry (0 when inside)."""
    k = M_PER_DEG_LAT * math.cos(math.radians(lat))

    def proj(x, y, z=None):
        return ((x - lon) * k, (y - lat) * M_PER_DEG_LAT)

    return transform(proj, shape(gj)).distance(Point(0, 0))


def within(lat1: float, lon1: float, lat2: float, lon2: float, radius_m: float) -> bool:
    return distance_m(lat1, lon1, lat2, lon2) <= radius_m


__all__ = [
    "LineString",
    "latlon",
    "line_geojson",
    "bearing_line",
    "bbox_deg",
    "normalize_multipolygon",
    "bounds",
    "distance_to_geometry_m",
    "within",
    "distance_m",
]
