"""Traffic signal agent (Tier 1)."""
from __future__ import annotations

from ..base import Agent, new_id
from ...services import loader


class TrafficAgent(Agent):
    name = "traffic-agent"
    tier = 1

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Per-corridor previous-delta buffer for 2-tick smoothing.
        self._prev_delta: dict[str, float] = {}

    def run(self, *, api_mode: str = "live", overlay: list[dict] | None = None) -> list[dict]:
        baseline = {c["id"]: c for c in loader.corridors()}
        live = loader.traffic_live()["corridors"]
        snapshot = {row["corridor_id"]: row for row in live}
        if overlay:
            for ov in overlay:
                snapshot[ov["corridor_id"]] = ov

        out: list[dict] = []
        for cid, row in snapshot.items():
            corridor = baseline.get(cid)
            if not corridor:
                continue
            cur = float(row.get("current_eta_s", corridor["baseline_eta_s"]))
            base = float(corridor["baseline_eta_s"])
            delta = (cur - base) / base if base else 0.0

            prev = self._prev_delta.get(cid, 0.0)
            self._prev_delta[cid] = delta

            trigger = None
            if delta > 1.5 and prev > 0.5:
                trigger = "severe_congestion"
            elif delta > 0.5 and prev > 0.3:
                trigger = "congestion_spike"

            if trigger is None:
                continue

            artifact = {
                "agent": self.name,
                "tier": self.tier,
                "run_id": self.run_id,
                "signal_id": new_id("trf"),
                "corridor_id": cid,
                "corridor_name": corridor.get("name"),
                "from_node": corridor.get("from_node"),
                "to_node": corridor.get("to_node"),
                "baseline_eta_s": base,
                "current_eta_s": cur,
                "delta": round(delta, 3),
                "trigger": trigger,
                "decision": "accept",
                "confidence": 0.9,
                "envelope": {
                    "agent": self.name,
                    "tier": 1,
                    "decision": "accept",
                    "confidence": 0.9,
                    "hypothesis": trigger,
                },
            }
            self.emit("signals/traffic", artifact)
            out.append(artifact)
        return out
