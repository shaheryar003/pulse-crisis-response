"""DispatchAgent (Tier 6) — emits dispatch tickets."""
from __future__ import annotations

from .base import Agent, new_id, iso_now


class DispatchAgent(Agent):
    name = "dispatch-agent"
    tier = 6

    def run(self, *, allocations: list[dict], incidents_by_id: dict[str, dict]) -> list[dict]:
        out: list[dict] = []
        for asg in allocations:
            inc = incidents_by_id.get(asg["incident_id"])
            if not inc:
                continue
            cls = inc["classification"]
            priority = self._priority(cls["severity"])
            supports = [a["asset_id"] for a in asg["assigned_assets"]]
            for asset in asg["assigned_assets"]:
                ticket = {
                    "dispatch_id": new_id("disp"),
                    "incident_id": cls["incident_id"],
                    "asset_id": asset["asset_id"],
                    "destination": {"zone": cls["zone"], "label": f"{cls['zone']} markaz junction"},
                    "eta_s": asset["eta_s"],
                    "priority": priority,
                    "instructions": self._instructions(cls, asset),
                    "supports": [a for a in supports if a != asset["asset_id"]],
                    "issued_at": iso_now(),
                    "status": "issued",
                }
                self.emit("dispatch", {
                    "agent": self.name,
                    "tier": self.tier,
                    "run_id": self.run_id,
                    **ticket,
                    "decision": "dispatched",
                    "confidence": 0.95,
                    "envelope": {
                        "agent": self.name,
                        "tier": 6,
                        "decision": "dispatched",
                        "confidence": 0.95,
                        "hypothesis": cls["type"],
                    },
                })
                out.append(ticket)
        return out

    def _priority(self, severity: int) -> str:
        if severity >= 4:
            return "urgent"
        if severity >= 3:
            return "high"
        return "normal"

    def _instructions(self, cls: dict, asset: dict) -> str:
        t = cls["type"]
        z = cls["zone"]
        return {
            "flood": f"Water rescue in {z}; secure low-lying residents; coordinate with traffic units to clear access.",
            "heatwave": f"Heat triage in {z}; set up cooling/clinic point; check elderly residents.",
            "fire": f"Engage fire in {z}; clear evacuation corridor; coordinate with ambulance for triage.",
            "water_main_burst": f"Isolate burst in {z}; coordinate with WASA crew; provide alternate water tanker.",
            "accident": f"Respond to incident in {z}; secure scene; expedite casualty transport.",
            "power_outage": f"Restore power in {z}; deploy generators to critical facilities.",
            "public_disorder": f"Maintain order in {z}; secure perimeter; route bystanders to safe zones.",
        }.get(t, f"Respond to incident in {z}; coordinate with supporting units.")
