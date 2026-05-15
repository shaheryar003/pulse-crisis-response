"""SimulationAgent (Tier 5) — before/after impact estimation."""
from __future__ import annotations

import math
from typing import Iterable

from .base import Agent, new_id


def _logistic(x: float, k: float = 0.0002, x0: float = 25000) -> float:
    return 1.0 / (1.0 + math.exp(-k * (x - x0)))


class SimulationAgent(Agent):
    name = "simulation-agent"
    tier = 5

    def run(self, *, allocations: list[dict], incidents_by_id: dict[str, dict]) -> list[dict]:
        out: list[dict] = []
        for asg in allocations:
            inc = incidents_by_id.get(asg["incident_id"])
            if not inc:
                continue

            # Dispatch sim
            for asset in asg["assigned_assets"]:
                out.append(self._sim_dispatch(inc, asset))
            # Public alert sim (one per incident)
            out.append(self._sim_public_alert(inc))
            # Reroute sim (one if congestion implied)
            out.append(self._sim_reroute(inc))
            # Hospital prep
            if inc["classification"]["type"] in ("flood", "fire", "accident", "heatwave"):
                out.append(self._sim_hospital(inc))

        for art in out:
            self.emit("sim", art)
        return out

    def _envelope(self, decision: str, confidence: float, *, hypothesis: str | None = None) -> dict:
        return {
            "agent": self.name,
            "tier": 5,
            "decision": decision,
            "confidence": confidence,
            "hypothesis": hypothesis,
        }

    def _sim_dispatch(self, inc: dict, asset: dict) -> dict:
        baseline = 18  # minutes
        after = max(2, int(asset["eta_s"] / 60))
        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": inc["classification"]["incident_id"],
            "action_id": new_id("act"),
            "action_type": "dispatch",
            "action": {"asset_id": asset["asset_id"], "destination": inc["classification"]["zone"]},
            "before_state": {"response_time_min": baseline, "congestion_delta": 0.0},
            "after_state": {"response_time_min": after, "congestion_delta": 0.12},
            "improvement": {"response_time_min": after - baseline},
            "side_effects": [
                {"kind": "congestion", "magnitude": 0.12, "scope": f"corridor near {inc['classification']['zone']} 20 min"},
                {"kind": "asset_unavailability", "asset_id": asset["asset_id"], "duration_min": 90},
            ],
            "evacuation_jam_probability": 0.0,
            "decision": "simulated",
            "confidence": 0.85,
            "envelope": self._envelope("simulated", 0.85, hypothesis="dispatch"),
        }

    def _sim_public_alert(self, inc: dict) -> dict:
        pop = inc["forecast"]["pop_affected"]["p50"]
        jam_prob_all = _logistic(pop)
        staged = jam_prob_all > 0.4
        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": inc["classification"]["incident_id"],
            "action_id": new_id("act"),
            "action_type": "alert",
            "action": {"target_pop": pop, "staged": staged, "batches": 3 if staged else 1},
            "before_state": {"evacuation_rate_per_min": 0},
            "after_state": {"evacuation_rate_per_min": 800 if staged else 3500},
            "improvement": {"orderly_evacuation": True},
            "side_effects": [
                {"kind": "evacuation_jam_probability", "magnitude": round(jam_prob_all, 3)},
            ],
            "evacuation_jam_probability": round(jam_prob_all if not staged else jam_prob_all * 0.25, 3),
            "requires_staging": staged,
            "decision": "simulated",
            "confidence": 0.8,
            "envelope": self._envelope("simulated", 0.8, hypothesis="public_alert"),
        }

    def _sim_reroute(self, inc: dict) -> dict:
        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": inc["classification"]["incident_id"],
            "action_id": new_id("act"),
            "action_type": "reroute",
            "action": {"avoid_zone": inc["classification"]["zone"]},
            "before_state": {"affected_corridor_congestion_delta": 2.0},
            "after_state": {"alternate_corridor_congestion_delta": 0.4, "primary_corridor_congestion_delta": 0.7},
            "improvement": {"primary_corridor_congestion_delta": -1.3},
            "side_effects": [
                {"kind": "alternate_corridor_load", "magnitude": 0.4},
                {"kind": "emergency_access_delta", "magnitude": -0.18, "scope": "ambulance ingress improved"},
            ],
            "evacuation_jam_probability": 0.0,
            "decision": "simulated",
            "confidence": 0.78,
            "envelope": self._envelope("simulated", 0.78, hypothesis="reroute"),
        }

    def _sim_hospital(self, inc: dict) -> dict:
        expected_patients = max(1, int(inc["forecast"]["pop_affected"]["p50"] * 0.002))
        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": inc["classification"]["incident_id"],
            "action_id": new_id("act"),
            "action_type": "hospital_prep",
            "action": {"expected_patients": expected_patients},
            "before_state": {"trauma_bay_ready": 8},
            "after_state": {"trauma_bay_ready": 12, "elective_slots_bumped": 4},
            "improvement": {"trauma_bay_ready": 4},
            "side_effects": [
                {"kind": "elective_bump", "magnitude": 4},
                {"kind": "staff_hours_cost", "magnitude": 18},
            ],
            "evacuation_jam_probability": 0.0,
            "decision": "simulated",
            "confidence": 0.82,
            "envelope": self._envelope("simulated", 0.82, hypothesis="hospital_prep"),
        }
