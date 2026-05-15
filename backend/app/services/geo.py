"""Point-in-polygon zone matching + great-circle ETA helpers.

Pure-Python implementation: ray-casting PIP + Haversine distance. No
shapely dependency so the agent fleet runs anywhere Python runs.
"""
from __future__ import annotations

import json
import math
from functools import lru_cache
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[3]


@lru_cache(maxsize=1)
def load_zones() -> list[tuple[str, dict, list[list[tuple[float, float]]]]]:
    """Returns (zone_id, properties, rings_as_lonlat).

    Each ring is a list of (lon, lat) tuples — matches GeoJSON ordering.
    """
    raw = json.loads((REPO_ROOT / "sim" / "fixtures" / "zones.geojson").read_text(encoding="utf-8"))
    out: list[tuple[str, dict, list[list[tuple[float, float]]]]] = []
    for feat in raw["features"]:
        zid = feat["properties"]["id"]
        coords = feat["geometry"]["coordinates"]
        # GeoJSON Polygon: [outer_ring, hole_ring, ...]; each ring = [[lon,lat],...]
        rings = [[(float(p[0]), float(p[1])) for p in ring] for ring in coords]
        out.append((zid, feat["properties"], rings))
    return out


def _point_in_ring(lon: float, lat: float, ring: list[tuple[float, float]]) -> bool:
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i]
        xj, yj = ring[j]
        intersect = ((yi > lat) != (yj > lat)) and (
            lon < (xj - xi) * (lat - yi) / (yj - yi + 1e-15) + xi
        )
        if intersect:
            inside = not inside
        j = i
    return inside


def _point_in_polygon(lon: float, lat: float, rings: list[list[tuple[float, float]]]) -> bool:
    if not rings:
        return False
    if not _point_in_ring(lon, lat, rings[0]):
        return False
    for hole in rings[1:]:
        if _point_in_ring(lon, lat, hole):
            return False
    return True


def zone_for(lat: float | None, lon: float | None) -> str | None:
    if lat is None or lon is None:
        return None
    for zid, _, rings in load_zones():
        if _point_in_polygon(lon, lat, rings):
            return zid
    return None


def _polygon_centroid(rings: list[list[tuple[float, float]]]) -> tuple[float, float]:
    """Centroid of the outer ring (cx_lon, cy_lat)."""
    if not rings:
        return (0.0, 0.0)
    ring = rings[0]
    n = len(ring)
    if n == 0:
        return (0.0, 0.0)
    sx = sum(p[0] for p in ring) / n
    sy = sum(p[1] for p in ring) / n
    return (sx, sy)


def zone_centroid(zone_id: str) -> tuple[float, float] | None:
    """Returns (lat, lon)."""
    for zid, _, rings in load_zones():
        if zid == zone_id:
            cx, cy = _polygon_centroid(rings)
            return (cy, cx)
    return None


def zones_in_radius(lat: float, lon: float, radius_km: float) -> list[str]:
    out: list[str] = []
    for zid, _, rings in load_zones():
        cx, cy = _polygon_centroid(rings)
        if haversine_km(lat, lon, cy, cx) <= radius_km:
            out.append(zid)
    return out


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0088
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlam / 2) ** 2
    return 2 * R * math.asin(min(1, math.sqrt(a)))


def eta_seconds(lat1: float, lon1: float, lat2: float, lon2: float, avg_kmh: float = 30.0) -> int:
    km = haversine_km(lat1, lon1, lat2, lon2)
    return int((km / avg_kmh) * 3600)


def zone_properties(zone_id: str) -> dict:
    for zid, props, _ in load_zones():
        if zid == zone_id:
            return props
    return {}
