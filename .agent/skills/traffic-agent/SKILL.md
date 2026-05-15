---
name: traffic-agent
description: Reads traffic/congestion data, compares to baseline, emits anomaly signals. Activate on each commander tick.
metadata:
  type: ingest
  version: 1.0.0
  tier: 1
---

# Traffic Signal Agent

## Purpose
Surface congestion anomalies that may indicate (or be caused by) a crisis.

## Inputs
- Mapbox Directions API for ETA between depot pairs.
- `sim/streams/traffic.json` baseline + live overlay.

## Procedure
1. For each monitored corridor (defined in `sim/fixtures/corridors.json`), fetch current ETA.
2. Compute `delta = (current_eta - baseline_eta) / baseline_eta`.
3. If `delta > 0.5` for 2 consecutive ticks → emit `congestion_spike`.
4. If `delta > 1.5` → emit `severe_congestion`.
5. If the corridor crosses a zone already flagged by Weather/Social → boost weight (correlated evidence).

## Emit
```json
{
  "agent": "traffic-agent",
  "signal_id": "trf_<ts>",
  "ts": "...",
  "corridor_id": "...",
  "from_node": "...",
  "to_node": "...",
  "baseline_eta_s": 480,
  "current_eta_s": 1620,
  "delta": 2.375,
  "trigger": "severe_congestion",
  "correlated_zones": ["G-10"],
  "envelope": { "tier": 1, "decision": "accept", "confidence": 0.9 }
}
```

## Rules
1. Two-tick smoothing prevents false alarms on transient micro-jams.
2. Never reroute on a single traffic signal alone — wait for fusion.
3. Cache last good response per corridor; degrade with stale flag.

## Failure Modes
- API quota exceeded: drop to baseline-only mode; emit `degraded:traffic-api`.
