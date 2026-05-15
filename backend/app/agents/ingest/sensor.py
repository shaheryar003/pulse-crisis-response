"""IoT sensor signal agent (Tier 1)."""
from __future__ import annotations

from collections import defaultdict
from typing import Iterable

from ..base import Agent, new_id
from ...services import loader

THRESHOLDS = {
    "water_level": 80,
    "aqi": 250,
    "transformer_load": 0.95,
    "smoke": 50,
    "structural_strain": 2000,
    "heat_index": 44,
}
TYPE_TO_TRIGGER = {
    "water_level": "urban_flood",
    "aqi": "air_hazard",
    "transformer_load": "outage_risk",
    "smoke": "fire",
    "structural_strain": "collapse_risk",
    "heat_index": "heat_critical",
}


class SensorAgent(Agent):
    name = "sensor-agent"
    tier = 1

    def run(self, readings: Iterable[dict] | None = None) -> list[dict]:
        readings = list(readings) if readings is not None else loader.sensor_readings()
        # Group by sensor_id, keep latest 3
        groups: dict[str, list[dict]] = defaultdict(list)
        for r in readings:
            groups[r["sensor_id"]].append(r)
        out: list[dict] = []
        for sid, rows in groups.items():
            rows_sorted = sorted(rows, key=lambda r: r["ts"])
            last3 = rows_sorted[-3:]
            sensor_type = last3[-1]["type"]
            thresh = THRESHOLDS.get(sensor_type)
            if thresh is None:
                continue
            breaches = sum(1 for r in last3 if float(r["value"]) >= thresh)
            if breaches < 2:
                continue
            latest = last3[-1]
            artifact = {
                "agent": self.name,
                "tier": self.tier,
                "run_id": self.run_id,
                "signal_id": new_id("sns"),
                "sensor_id": sid,
                "type": sensor_type,
                "zone": latest.get("zone"),
                "value": float(latest["value"]),
                "threshold": thresh,
                "consecutive_breaches": breaches,
                "trigger": TYPE_TO_TRIGGER.get(sensor_type),
                "decision": "accept",
                "confidence": 0.98 if breaches == 3 else 0.85,
                "envelope": {
                    "agent": self.name,
                    "tier": 1,
                    "decision": "accept",
                    "confidence": 0.98 if breaches == 3 else 0.85,
                    "hypothesis": TYPE_TO_TRIGGER.get(sensor_type),
                },
            }
            self.emit("signals/sensor", artifact)
            out.append(artifact)
        return out
