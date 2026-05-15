---
name: prioritizer
description: Ranks all live incidents by severity × vulnerability × urgency. Provides explainable trade-off rationale. Activate before each allocation round.
metadata:
  type: prioritizer
  version: 1.0.0
  tier: 5
---

# Multi-Crisis Prioritizer

## Inputs
List of (Classifier + Forecaster + HistoricalContext) tuples.

## Procedure

### 1. Priority score per incident
```
priority = (
    0.35 * severity / 5
  + 0.20 * min(1, pop_affected_p50 / 50000)
  + 0.15 * vulnerability_index
  + 0.10 * (1 - peak_eta_min / 60)        # urgency: sooner = higher
  + 0.10 * (spread_risk_value / 2)         # low=0, med=1, high=2
  + 0.10 * confidence
)
```

### 2. Rank
Sort descending. Ties broken by earlier `ts_first_signal`.

### 3. Trade-off explanation
For each incident, generate a rationale:
- "Ranked 1 because severity=4 + 28k affected + medium spread."
- "Ranked 2 despite higher severity because lower confidence (0.55) and fewer affected."

### 4. Resource budget hint
Tag each incident with `recommended_resource_share` (% of total available pool) using a softmax over priorities.

## Emit
```json
{
  "agent": "prioritizer",
  "round_id": "...",
  "ts": "...",
  "ranking": [
    {"incident_id": "inc_g10_flood", "rank": 1, "priority": 0.82,
     "rationale": "...", "recommended_resource_share": 0.62},
    {"incident_id": "inc_f7_heat",   "rank": 2, "priority": 0.66,
     "rationale": "...", "recommended_resource_share": 0.38}
  ],
  "trade_offs": [
    "G-10 takes 4 of 6 rescue teams; F-7 medical outreach with 2 ambulances + 1 mobile clinic.",
    "If a third incident arises in this round, resources will be insufficient — escalate to provincial."
  ],
  "envelope": { "tier": 5, "decision": "ranked", "confidence": 0.9 }
}
```

## Rules
1. Always emit `trade_offs` strings — these are the artifact judges score on.
2. When resources < incidents-needing-action, declare a `resource_shortfall` and flag for escalation.
3. Never starve a lower-ranked incident entirely if pop_affected > 1000 — guarantee at least 1 asset (`floor_assignment`).
