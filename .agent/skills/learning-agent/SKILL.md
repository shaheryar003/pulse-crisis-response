---
name: learning-agent
description: Records every round's outcome to history; tunes credibility/threshold parameters per source over time. Activate at end of every round and after every recall.
metadata:
  type: learning
  version: 1.0.0
  tier: 7
---

# Learning Agent

## Inputs
- Round artifacts.
- Recall artifacts.
- Operator overrides (when a human disagrees with a classification).

## Procedure

### 1. Per-round logging
Append to `db.history`:
- incident_id, type, severity, confidence
- signal_sources_contributing
- actions_taken
- outcome (resolved_ts, retracted_ts, casualties_avoided_estimate)

### 2. Source trust updates
For each signal contributing to a confirmed-correct classification:
`trust_new = trust_old + α * (1 - trust_old)` with α=0.05

For each signal contributing to a retracted classification:
`trust_new = trust_old - β * trust_old` with β=0.10

Capped to [0.05, 0.99] (never zero so source can recover).

### 3. Threshold tuning (weekly batch)
- Recall < target → lower classification confidence floor for that type.
- Precision < target → raise confidence floor.
- Tracked in `db.tuning_log`.

### 4. Operator override recording
When a human flips a classification, treat operator as ground-truth signal with trust=1.0.

## Emit
```json
{
  "agent": "learning-agent",
  "round_id": "...",
  "ts": "...",
  "updates": {
    "trust_deltas": [
      {"source_type": "social", "user_id_hash": "ab12", "delta": +0.05},
      {"source_type": "field_report", "user_id_hash": "ef89", "delta": +0.05}
    ],
    "threshold_changes": []
  },
  "envelope": { "tier": 7, "decision": "learned", "confidence": 0.99 }
}
```

## Rules
1. No update without explicit ground truth (recall outcome OR operator override).
2. Trust updates are persisted before round close.
3. Threshold changes require ≥30 data points; otherwise queued.

## Failure Modes
- History DB unavailable: queue updates in memory ring buffer; retry on every round; alert ops if buffer > 100.
