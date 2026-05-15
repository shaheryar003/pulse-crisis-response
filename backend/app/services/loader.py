"""Fixture loaders — cached on import for hot paths."""
from __future__ import annotations

import csv
import json
from functools import lru_cache
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
SIM = REPO_ROOT / "sim"


@lru_cache(maxsize=1)
def facilities() -> dict:
    return json.loads((SIM / "fixtures" / "facilities.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def resources() -> list[dict]:
    return json.loads((SIM / "fixtures" / "resources.json").read_text(encoding="utf-8"))["fleet"]


@lru_cache(maxsize=1)
def vulnerability() -> dict:
    return json.loads((SIM / "fixtures" / "vulnerability.json").read_text(encoding="utf-8"))["zones"]


@lru_cache(maxsize=1)
def corridors() -> list[dict]:
    return json.loads((SIM / "fixtures" / "corridors.json").read_text(encoding="utf-8"))["corridors"]


@lru_cache(maxsize=1)
def historical() -> dict:
    return json.loads((SIM / "streams" / "historical.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def weather_live() -> dict:
    return json.loads((SIM / "streams" / "weather.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def weather_cache_fallback() -> dict:
    return json.loads((SIM / "streams" / "weather_cache.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def traffic_live() -> dict:
    return json.loads((SIM / "streams" / "traffic.json").read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def social_posts() -> list[dict]:
    out: list[dict] = []
    with (SIM / "streams" / "social.jsonl").open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            out.append(json.loads(line))
    return out


def social_post_by_id(post_id: str) -> dict | None:
    for p in social_posts():
        if p.get("id") == post_id:
            return p
    return None


@lru_cache(maxsize=1)
def sensor_readings() -> list[dict]:
    out: list[dict] = []
    with (SIM / "streams" / "sensors.jsonl").open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            out.append(json.loads(line))
    return out


@lru_cache(maxsize=1)
def emergency_calls() -> list[dict]:
    out: list[dict] = []
    with (SIM / "streams" / "calls.csv").open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            out.append(dict(row))
    return out


def call_by_id(call_id: str) -> dict | None:
    for c in emergency_calls():
        if c.get("call_id") == call_id:
            return c
    return None


def depot_geo(depot_id: str) -> dict | None:
    fac = facilities()
    for bucket in ("depots", "fire_stations", "police_stations"):
        for d in fac.get(bucket, []):
            if d.get("id") == depot_id:
                return d.get("geo")
    return None
