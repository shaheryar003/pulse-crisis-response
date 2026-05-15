---
name: sensor-agent
description: Ingests mock IoT sensors (water level, AQI, transformer load, smoke). Threshold detection on each. Activate on each commander tick.
metadata:
  type: ingest
  version: 1.0.0
  tier: 1
---

# IoT Sensor Signal Agent

## Inputs
`sim/streams/sensors.jsonl`. Each line: `{sensor_id, type, geo, ts, value, unit, health}`.

## Sensor types + thresholds
| Type | Unit | Crisis threshold |
|---|---|---|
| water_level | cm | > 80 (urban flood) |
| aqi | µg/m³ pm2.5 | > 250 (hazard) |
| transformer_load | kVA | > 0.95 * capacity (outage risk) |
| smoke | ppm | > 50 (fire) |
| structural_strain | µε | > 2000 (collapse risk) |

## Procedure
1. Group by `(sensor_id, type)`, take latest 3 readings.
2. If 2/3 above threshold → emit signal.
3. If sensor `health != ok` → emit only if 3/3 above threshold (avoid faulty-sensor false alarms).
4. Map geo to zone.

## Emit
```json
{
  "agent": "sensor-agent",
  "signal_id": "sns_<sensor>_<ts>",
  "ts": "...",
  "sensor_id": "...",
  "type": "water_level",
  "zone": "G-10",
  "value": 92.4,
  "threshold": 80,
  "consecutive_breaches": 3,
  "envelope": { "tier": 1, "decision": "accept", "confidence": 0.95 }
}
```

## Rules
1. Always log raw values for audit even when below threshold (rolling 1h ring buffer).
2. Disregard sensors marked `decommissioned`.
3. Adjacent same-type sensors confirming each other boost confidence to 0.98.

## Failure Modes
- Sensor offline > 5 min: emit `sensor:silent` so operators know coverage gap.
- Stream malformed: skip line, log, continue.
