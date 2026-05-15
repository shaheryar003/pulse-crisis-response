"""RecallAgent (Tier 7) — handles classification flips, retractions, audit log."""
from __future__ import annotations

from .base import Agent, new_id


class RecallAgent(Agent):
    name = "recall-agent"
    tier = 7

    def run(self, *, original: dict, new_classification: dict, contributing_signals: list[dict], dispatched: list[dict], alerts: list[dict]) -> dict:
        audit = {
            "audit_id": new_id("audit"),
            "incident_id": original["incident_id"],
            "ts_flip": new_classification["ts"],
            "original": {
                "type": original["type"],
                "severity": original["severity"],
                "confidence": original["confidence"],
                "actions_taken": [d["dispatch_id"] for d in dispatched],
            },
            "new": {
                "type": new_classification["type"],
                "severity": new_classification["severity"],
                "confidence": new_classification["confidence"],
            },
            "evidence_at_flip": [
                {"agent": s.get("agent"), "signal_id": s.get("signal_id"), "credibility": s.get("credibility"), "decision": s.get("envelope", {}).get("decision")}
                for s in contributing_signals
            ],
            "responsible_agent_chain": ["fusion-agent", "classifier-agent", "verification-agent", "verification-agent:recovery"],
            "user_impact": {
                "recipients_of_retraction": sum(a.get("delivery", {}).get("estimated_recipients", 0) for a in alerts if a.get("channel") == "public_push"),
                "responders_recalled": len(dispatched),
            },
        }

        retraction_msg_en = (
            f"Correction: earlier alert for {original.get('zone', 'affected area')} ({original['type']}) has been retracted. "
            f"Updated classification: {new_classification['type']}. Apologies — utility partners are responding."
        )

        actions = ["alert_retracted", "responders_reassigned", "audit_logged"]

        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": original["incident_id"],
            "audit": audit,
            "retraction_message_en": retraction_msg_en,
            "actions": actions,
            "decision": "recalled",
            "confidence": 0.95,
            "envelope": {
                "agent": self.name,
                "tier": 7,
                "decision": "recalled",
                "confidence": 0.95,
                "hypothesis": new_classification["type"],
            },
        }
        self.emit("recall", artifact)
        return artifact
