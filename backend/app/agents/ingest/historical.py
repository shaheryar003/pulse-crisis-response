"""Historical context provider (Tier 1)."""
from __future__ import annotations

from ..base import Agent
from ...services import loader


class HistoricalAgent(Agent):
    name = "historical-agent"
    tier = 1

    def run(self, *, zone: str, incident_type: str | None = None) -> dict:
        hist = loader.historical()
        vuln = loader.vulnerability().get(zone, {})
        by_zone_type = hist.get("by_zone_type", {})
        key = f"{zone}:{incident_type}" if incident_type else None
        history_summary = by_zone_type.get(key, {})
        examples = [i for i in hist.get("incidents", []) if i.get("zone") == zone]
        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "zone": zone,
            "vulnerability_index": vuln.get("vulnerability_index", 0.5),
            "factors": {
                "hospital_density_per_10k": vuln.get("hospital_density_per_10k"),
                "evacuation_routes": vuln.get("evacuation_routes"),
            },
            "history_summary": history_summary,
            "historical_examples": [
                f"{e['ts']} {e['type']} sev={e['severity']}" for e in examples[:3]
            ],
            "decision": "context_provided",
            "confidence": 0.9,
            "envelope": {
                "agent": self.name,
                "tier": 1,
                "decision": "context_provided",
                "confidence": 0.9,
                "hypothesis": None,
            },
        }
        self.emit("signals/historical", artifact)
        return artifact
