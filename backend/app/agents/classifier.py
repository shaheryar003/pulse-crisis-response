"""ClassifierAgent (Tier 3) — type + severity with ensembled confidence."""
from __future__ import annotations

import random
import statistics
from typing import Iterable

from .base import Agent, new_id
from ..services.loader import vulnerability
from ..services.llm import get_llm


TYPES_CLOSED_SET = {
    "flood", "heatwave", "accident", "infrastructure_failure", "water_main_burst",
    "power_outage", "fire", "gas_leak", "public_disorder", "disease_cluster", "other",
}


def _severity_from_signals(*, type_: str, pop_in_radius: int, sensor_max_value: float | None, social_count: int) -> int:
    # Per-rubric, severity is data-driven.
    s = 1
    if pop_in_radius >= 50000:
        s = max(s, 5)
    elif pop_in_radius >= 10000:
        s = max(s, 4)
    elif pop_in_radius >= 1000:
        s = max(s, 3)
    elif pop_in_radius >= 100:
        s = max(s, 2)
    if type_ == "flood" and sensor_max_value and sensor_max_value >= 80:
        s = max(s, 4)
    if type_ == "heatwave" and sensor_max_value and sensor_max_value >= 45:
        s = max(s, 4)
    if type_ == "fire" and sensor_max_value and sensor_max_value >= 100:
        s = max(s, 4)
    if type_ == "water_main_burst":
        s = max(2, min(s, 3))
    if social_count >= 10:
        s = min(5, s + 1)
    return s


class ClassifierAgent(Agent):
    name = "classifier-agent"
    tier = 3

    def run(self, *, candidate: dict, verification: dict, signals: list[dict]) -> dict:
        # Heuristic base
        type_base = verification["hypotheses"][0]["label"] if verification.get("hypotheses") else candidate.get("hypothesis_seed", "other")
        if type_base not in TYPES_CLOSED_SET:
            type_base = "other"

        zone = candidate.get("zone")
        zone_pop = self._pop_for_zone(zone)
        sensor_max = max(
            (float(s.get("value", 0)) for s in signals if s.get("agent") == "sensor-agent"),
            default=None,
        )
        social_count = sum(1 for s in signals if s.get("agent") == "social-agent")
        sev_base = _severity_from_signals(
            type_=type_base, pop_in_radius=zone_pop, sensor_max_value=sensor_max, social_count=social_count
        )

        # Ensemble (5 mock LLM votes with controlled jitter — replicates Gemini Flash ensemble)
        ensemble = self._ensemble_vote(
            type_base=type_base, sev_base=sev_base,
            verification=verification, signals=signals,
        )
        type_votes = [v["type"] for v in ensemble]
        type_final = max(set(type_votes), key=type_votes.count)
        severities = sorted(v["severity"] for v in ensemble)
        sev_final = severities[len(severities) // 2]

        agreement = sum(1 for v in ensemble if v["type"] == type_final) / len(ensemble)
        top_score = verification["hypotheses"][0]["score"] if verification.get("hypotheses") else 0.5
        confidence = max(0.05, min(0.99, agreement * top_score))

        # Guardrails
        social_only = all(s.get("agent") == "social-agent" for s in signals)
        sensor_corroborates = any(s.get("agent") == "sensor-agent" for s in signals)
        weather_corroborates = any(s.get("agent") == "weather-agent" for s in signals)
        if social_only:
            confidence = min(confidence, 0.65)
        if sensor_corroborates and weather_corroborates:
            confidence = max(confidence, 0.70)

        # Rationale via LLM (mock-safe)
        llm = get_llm().complete(
            f"Classify zone={zone} type={type_final} sev={sev_final} signals={len(signals)}",
            temperature=0.4,
        )

        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": new_id("inc"),
            "candidate_id": candidate.get("candidate_id"),
            "zone": zone,
            "type": type_final,
            "severity": sev_final,
            "confidence": round(confidence, 3),
            "ensemble_votes": ensemble,
            "rationale": llm.text,
            "low_confidence": confidence < 0.4,
            "decision": "classified",
            "envelope": {
                "agent": self.name,
                "tier": 3,
                "decision": "classified" if confidence >= 0.4 else "low_confidence_classification",
                "confidence": round(confidence, 3),
                "hypothesis": type_final,
            },
        }
        self.emit("classify", artifact)
        return artifact

    def _ensemble_vote(self, *, type_base: str, sev_base: int, verification: dict, signals: list[dict]) -> list[dict]:
        rng = random.Random(hash((type_base, sev_base, len(signals))) & 0xFFFFFFFF)
        alt = verification["hypotheses"][1]["label"] if len(verification.get("hypotheses", [])) > 1 else None
        votes: list[dict] = []
        for i in range(5):
            # 80% chance pick base type; otherwise alt
            t = type_base if rng.random() < 0.8 or not alt else alt
            sev_jitter = sev_base + rng.choice([-1, 0, 0, 0, +1])
            sev_jitter = max(1, min(5, sev_jitter))
            votes.append({"type": t, "severity": sev_jitter})
        return votes

    def _pop_for_zone(self, zone: str | None) -> int:
        if not zone:
            return 0
        from ..services.geo import zone_properties
        return int(zone_properties(zone).get("population", 0))
