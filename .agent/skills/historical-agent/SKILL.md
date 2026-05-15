---
name: historical-agent
description: Provides historical and vulnerability context for a zone or incident. Activate when FusionAgent flags a candidate incident.
metadata:
  type: context
  version: 1.0.0
  tier: 1
---

# Historical Context Agent

## Purpose
Anchor live signals in historical priors and vulnerability data so the Severity tier doesn't reinvent context.

## Inputs
- `sim/streams/historical.json` — past 3 years of incidents by zone + type.
- `sim/fixtures/vulnerability.json` — per-zone population, income decile, elderly %, hospital density, evacuation routes.

## Procedure
1. For requested zone, return:
   - Past 3 years' flood/heatwave/etc. frequency
   - Average duration + severity
   - Worst-case event reference
   - Vulnerability factors
2. Compute a `vulnerability_index` ∈ [0,1]:
```
v = 0.3*(1 - income_decile/10)
  + 0.2*elderly_pct
  + 0.2*(1 - hospital_density_norm)
  + 0.15*(historical_freq_for_type / max_freq)
  + 0.15*(1 - evacuation_route_count_norm)
```

## Emit
```json
{
  "agent": "historical-agent",
  "zone": "F-7-katchi",
  "ts": "...",
  "vulnerability_index": 0.74,
  "factors": {
    "income_decile": 2,
    "elderly_pct": 0.18,
    "hospital_density_per_10k": 0.4,
    "historical_heatwave_freq": 4,
    "evacuation_routes": 2
  },
  "historical_examples": ["2024-06-12 heatwave, 12 hospitalizations"],
  "envelope": { "tier": 1, "decision": "context_provided", "confidence": 0.9 }
}
```

## Rules
1. Read-only; never modifies incident state.
2. If zone unknown, return `vulnerability_index: 0.5` (neutral prior) and log gap.
