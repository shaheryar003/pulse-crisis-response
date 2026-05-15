"""SeverityForecaster (Tier 4) — radius, population, duration, peak, uncertainty."""
from __future__ import annotations

import math
import random
import statistics

from .base import Agent
from ..services.geo import zone_properties
from ..services.loader import vulnerability


def _quantiles(samples: list[float]) -> dict[str, float]:
    if not samples:
        return {"p10": 0.0, "p50": 0.0, "p90": 0.0}
    s = sorted(samples)
    def _q(p: float) -> float:
        if not s:
            return 0.0
        idx = max(0, min(len(s) - 1, int(round(p * (len(s) - 1)))))
        return s[idx]
    return {"p10": round(_q(0.1), 3), "p50": round(_q(0.5), 3), "p90": round(_q(0.9), 3)}


SPREAD_BY_TYPE = {"flood": "medium", "fire": "high", "disease_cluster": "high"}


class SeverityForecaster(Agent):
    name = "severity-forecaster"
    tier = 4

    def run(self, *, incident: dict, signals: list[dict], n_samples: int = 200) -> dict:
        rng = random.Random(hash(incident["incident_id"]) & 0xFFFFFFFF)
        type_ = incident["type"]
        zone = incident["zone"]
        zone_props = zone_properties(zone)
        zone_pop = int(zone_props.get("population", 10000))
        vuln = vulnerability().get(zone, {})
        rain_signals = [s for s in signals if s.get("agent") == "weather-agent"]
        rain_mmhr = next((float(s.get("vars", {}).get("rain_mmhr") or 0) for s in rain_signals if s.get("vars", {}).get("rain_mmhr")), 0.0)

        radii: list[float] = []
        durations: list[float] = []
        pops: list[float] = []
        for _ in range(n_samples):
            r = self._sample_radius(type_, rain_mmhr * rng.uniform(0.9, 1.1), rng)
            d = self._sample_duration(type_, rng)
            p = zone_pop * rng.uniform(0.5, 1.0) * min(1.0, r / 1.5)
            radii.append(r)
            durations.append(d)
            pops.append(p)

        rq = _quantiles(radii)
        dq = _quantiles(durations)
        pq = _quantiles(pops)
        peak_eta = self._peak_eta(type_, rain_mmhr)

        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": incident["incident_id"],
            "radius_km": rq,
            "pop_affected": {"p10": int(pq["p10"]), "p50": int(pq["p50"]), "p90": int(pq["p90"])},
            "peak_eta_min": peak_eta,
            "duration_min": {"p10": int(dq["p10"]), "p50": int(dq["p50"]), "p90": int(dq["p90"])},
            "spread_risk": SPREAD_BY_TYPE.get(type_, "low"),
            "vulnerability_index": vuln.get("vulnerability_index", 0.5),
            "vulnerable_pop_pct": round(vuln.get("vulnerability_index", 0.5) * 0.4, 3),
            "decision": "forecast_complete",
            "confidence": 0.72,
            "envelope": {
                "agent": self.name,
                "tier": 4,
                "decision": "forecast_complete",
                "confidence": 0.72,
                "hypothesis": type_,
            },
        }
        self.emit("forecast", artifact)
        return artifact

    def _sample_radius(self, type_: str, rain_mmhr: float, rng: random.Random) -> float:
        if type_ == "flood":
            t_minutes = rng.uniform(20, 80)
            return math.sqrt(max(0.0, rain_mmhr) * t_minutes / 30.0) * 0.4
        if type_ == "fire":
            return rng.uniform(0.1, 0.8)
        if type_ == "heatwave":
            return rng.uniform(0.5, 1.5)
        if type_ == "water_main_burst":
            return rng.uniform(0.1, 0.4)
        if type_ == "power_outage":
            return rng.uniform(0.5, 2.5)
        return rng.uniform(0.2, 1.0)

    def _sample_duration(self, type_: str, rng: random.Random) -> float:
        if type_ == "flood":
            return rng.uniform(180, 480)
        if type_ == "heatwave":
            return rng.uniform(240, 720)
        if type_ == "fire":
            return rng.uniform(60, 240)
        if type_ == "water_main_burst":
            return rng.uniform(180, 480)
        if type_ == "power_outage":
            return rng.uniform(60, 360)
        return rng.uniform(30, 120)

    def _peak_eta(self, type_: str, rain_mmhr: float) -> int:
        if type_ == "flood":
            return max(20, min(120, int(60 - rain_mmhr * 0.5)))
        if type_ == "heatwave":
            return 90
        if type_ == "fire":
            return 25
        if type_ == "water_main_burst":
            return 30
        return 45
