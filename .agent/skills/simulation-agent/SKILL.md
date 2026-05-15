---
name: simulation-agent
description: For each proposed action, simulates before/after with congestion, response-time, evacuation, hospital-load side effects. Activate in parallel with Allocator.
metadata:
  type: simulator
  version: 1.0.0
  tier: 5
---

# Action Impact Simulator

## Per-action simulations

### A. Dispatch a rescue/ambulance/etc.
- Before: response time = baseline ETA.
- After: response time = current ETA from allocator.
- Side effect: route edges marked +30% load for next 20 min → recompute median speed delta along corridor.

### B. Traffic reroute
- Before: vehicles on Corridor-X.
- After: redistributed across alternates per shortest-path with capacity penalty.
- Side effect: alternate corridor congestion delta; emergency vehicle response time delta.

### C. Public alert
- Staged (3 batches @ 10-min intervals): peak evacuation rate p50 = 800/min.
- All-at-once: peak rate p50 = 3500/min → high jam probability (logistic on pop_affected).
- Side effect: emergency vehicle access delta at corridor inflection points.

### D. Hospital pre-position
- Before: trauma bay occupancy = baseline.
- After: prepared for +N expected patients.
- Side effect: elective slot bumps; cost in staff hours.

### E. Utility escalation
- Before: outage tier-2.
- After: tier-1 with crew dispatch.
- Side effect: cross-zone load shed possible if widespread.

## Emit (one artifact per action)
```json
{
  "agent": "simulation-agent",
  "incident_id": "...",
  "action_id": "act_<uuid>",
  "ts": "...",
  "action_type": "dispatch | reroute | alert | hospital | utility",
  "before_state": {"response_time_min": 18, "congestion_delta": 0, ...},
  "action": {"asset_id": "rescue-3", "destination": "..."},
  "after_state": {"response_time_min": 9, "congestion_delta": 0.12, ...},
  "improvement": {"response_time_min": -9},
  "side_effects": [
    {"kind": "congestion", "magnitude": 0.12, "scope": "Margalla Rd 20 min"},
    {"kind": "asset_unavailability", "asset_id": "rescue-3", "duration_min": 90}
  ],
  "evacuation_jam_probability": 0.08,
  "envelope": { "tier": 5, "decision": "simulated", "confidence": 0.85 }
}
```

## Rules
1. Always quantify side effects, never just list them.
2. If a public alert action has `evacuation_jam_probability > 0.4`, mark `requires_staging`.
3. Simulations are advisory; Allocator decisions are not overridden, but flagged for command-center attention.
