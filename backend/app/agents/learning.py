"""LearningAgent (Tier 7) — round outcome logging + trust updates."""
from __future__ import annotations

from .base import Agent


class LearningAgent(Agent):
    name = "learning-agent"
    tier = 7

    def run(self, *, round_summary: dict, recall: dict | None = None) -> dict:
        trust_deltas = []
        if recall:
            for ev in recall["audit"]["evidence_at_flip"]:
                if ev.get("agent") == "citizen-report-agent" and (ev.get("credibility") or 0) >= 0.7:
                    trust_deltas.append({"source_type": "citizen", "delta": +0.05, "reason": "expert_correction_confirmed"})
                if ev.get("agent") == "social-agent" and ev.get("decision") == "unverified":
                    trust_deltas.append({"source_type": "social", "delta": -0.10, "reason": "contributed_to_overclassification"})

        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "round_summary": round_summary,
            "updates": {"trust_deltas": trust_deltas, "threshold_changes": []},
            "decision": "learned",
            "confidence": 0.99,
            "envelope": {
                "agent": self.name,
                "tier": 7,
                "decision": "learned",
                "confidence": 0.99,
                "hypothesis": None,
            },
        }
        self.emit("learn", artifact)
        return artifact
