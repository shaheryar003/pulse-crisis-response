---
name: resource-allocator
description: Bipartite optimal assignment of available assets to prioritized incidents using Hungarian algorithm with weighted cost. Activate after Prioritizer.
metadata:
  type: allocator
  version: 1.0.0
  tier: 5
---

# Resource Allocator

## Inputs
- Prioritized incidents with `recommended_resource_share` + capability needs.
- Asset roster from `sim/fixtures/resources.json` with current `status`, `location`, `capability_tags`.

## Procedure

### 1. Capability matching
Each incident type has a required capability set:
| Type | Required |
|---|---|
| flood | rescue, police_traffic, ambulance, drone(optional) |
| heatwave | ambulance, mobile_clinic, water_tanker |
| fire | fire_unit, ambulance, police_traffic |
| accident | ambulance, police_traffic, tow |
| power_outage | utility_crew, generator |
| water_main_burst | utility_crew, police_traffic |

### 2. Cost matrix
For each (asset, incident) pair where asset has at least one required capability:
```
cost = travel_time_s
     + α * (1 - capability_overlap_fraction) * 600
     - β * priority_score * 300
     + γ * fatigue_penalty(asset)
```
α=1.0, β=1.0, γ=0.3 default.
- `travel_time_s` from Mapbox or precomputed depot-zone table.
- `capability_overlap_fraction` = matched / required.
- `fatigue_penalty` = hours on duty / 8.

### 3. Solve
- Build cost matrix incidents × assets.
- For incidents needing >1 asset of a type, replicate the row.
- Use `scipy.optimize.linear_sum_assignment` (Hungarian).
- Honor `floor_assignment` from Prioritizer.

### 4. Validate
- Each incident must end with at least the floor capability set, else flag `unmet_need`.
- Recompute and reallocate if a higher-priority incident has unmet need while lower has surplus.

## Emit
```json
{
  "agent": "resource-allocator",
  "round_id": "...",
  "ts": "...",
  "assignments": [
    {"incident_id": "inc_g10_flood",
     "assigned_assets": [
       {"asset_id": "rescue-3", "type": "rescue", "eta_s": 540, "from": "Depot-1"},
       {"asset_id": "police-7", "type": "police_traffic", "eta_s": 420}
     ],
     "capability_coverage": 1.0
    },
    {"incident_id": "inc_f7_heat",
     "assigned_assets": [
       {"asset_id": "amb-12", "type": "ambulance", "eta_s": 380}
     ],
     "capability_coverage": 0.66,
     "unmet": ["water_tanker"]}
  ],
  "total_cost": 4860,
  "alternatives_considered": [
    "Sending amb-12 to G-10 saves 60s but leaves F-7 fully unstaffed."
  ],
  "envelope": { "tier": 5, "decision": "allocated", "confidence": 0.92 }
}
```

## Rules
1. Always emit `alternatives_considered` — at minimum the second-best assignment for the highest-priority incident.
2. Never assign an asset already in `en_route` status to another incident in the same round.
3. Drones get auto-attached to flood/fire incidents within their range — no Hungarian for them, additive only.
