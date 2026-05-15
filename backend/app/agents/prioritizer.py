"""PrioritizerAgent (Tier 5) — explainable multi-crisis ranking."""
from __future__ import annotations

import math
from typing import Iterable

from .base import Agent, new_id


SPREAD_VALUE = {"low": 0, "medium": 1, "high": 2}


def _softmax(xs: list[float]) -> list[float]:
    if not xs:
        return []
    m = max(xs)
    exps = [math.exp(x - m) for x in xs]
    s = sum(exps) or 1.0
    return [e / s for e in exps]


class PrioritizerAgent(Agent):
    name = "prioritizer"
    tier = 5

    def run(self, *, incidents: list[dict], available_assets: int) -> dict:
        scored = []
        for inc in incidents:
            severity = inc["classification"]["severity"]
            confidence = inc["classification"]["confidence"]
            pop_p50 = inc["forecast"]["pop_affected"]["p50"]
            peak = inc["forecast"]["peak_eta_min"]
            spread = inc["forecast"]["spread_risk"]
            vuln = inc["forecast"].get("vulnerability_index", 0.5)
            priority = (
                0.35 * severity / 5
                + 0.20 * min(1.0, pop_p50 / 50000)
                + 0.15 * vuln
                + 0.10 * (1 - min(1.0, peak / 60.0))
                + 0.10 * (SPREAD_VALUE.get(spread, 0) / 2.0)
                + 0.10 * confidence
            )
            scored.append({"incident": inc, "priority": round(priority, 3)})
        scored.sort(key=lambda x: (-x["priority"], x["incident"]["candidate"].get("ts_first_signal", "")))

        shares = _softmax([s["priority"] * 4 for s in scored])
        ranking = []
        trade_offs: list[str] = []
        for rank, (s, share) in enumerate(zip(scored, shares), start=1):
            inc = s["incident"]
            cls = inc["classification"]
            fc = inc["forecast"]
            ranking.append({
                "incident_id": cls["incident_id"],
                "rank": rank,
                "priority": s["priority"],
                "type": cls["type"],
                "severity": cls["severity"],
                "zone": cls["zone"],
                "pop_p50": fc["pop_affected"]["p50"],
                "rationale": self._rationale(rank, cls, fc, s["priority"]),
                "recommended_resource_share": round(share, 3),
                "floor_assignment": fc["pop_affected"]["p50"] > 1000,
            })

        if len(ranking) >= 2:
            top = ranking[0]
            second = ranking[1]
            trade_offs.append(
                f"{top['zone']} takes ~{int(top['recommended_resource_share']*100)}% of assets due to higher priority "
                f"({top['priority']} vs {second['priority']}); {second['zone']} retains floor coverage to avoid starvation."
            )
        resource_shortfall = sum(1 for r in ranking if r["floor_assignment"]) > available_assets
        if resource_shortfall:
            trade_offs.append("Resource shortfall predicted — escalation to provincial pool recommended.")

        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "round_id": new_id("round"),
            "ranking": ranking,
            "trade_offs": trade_offs,
            "resource_shortfall": resource_shortfall,
            "decision": "ranked",
            "confidence": 0.9,
            "envelope": {
                "agent": self.name,
                "tier": 5,
                "decision": "ranked",
                "confidence": 0.9,
                "hypothesis": None,
            },
        }
        self.emit("priority", artifact)
        return artifact

    def _rationale(self, rank: int, cls: dict, fc: dict, priority: float) -> str:
        return (
            f"Ranked {rank}: type={cls['type']}, severity={cls['severity']}, "
            f"pop_p50={fc['pop_affected']['p50']}, spread={fc['spread_risk']}, "
            f"confidence={cls['confidence']}, computed_priority={priority:.3f}."
        )
