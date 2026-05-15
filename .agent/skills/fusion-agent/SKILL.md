---
name: fusion-agent
description: Spatiotemporal clustering of Tier-1 signals into candidate incidents with multi-source corroboration weights. Activate after Tier-1 fan-in.
metadata:
  type: fusion
  version: 1.0.0
  tier: 2
---

# Fusion Agent

## Purpose
Take a heterogeneous bag of signals and cluster them into candidate incidents, weighted by source diversity and credibility.

## Inputs
List of Tier-1 signal envelopes.

## Procedure

### 1. Spatial clustering
- Project all signals with geo to a metric CRS (EPSG:3857).
- DBSCAN with eps=500m, min_samples=2 (signals from different sources count separately).
- Anonymous-geo signals: bucketed by zone string match.

### 2. Temporal windowing
- Within each spatial cluster, signals within a 20-min rolling window remain together.
- Older signals decay weight by `exp(-Δt_minutes / 30)`.

### 3. Source-diversity bonus
- A cluster with N distinct source types gets `diversity_score = 1 - (1/N)`.
- 1 source: 0.0; 2: 0.5; 3: 0.67; 4: 0.75; 5+: 0.8+
- Multi-source clusters survive a single-source contradiction; single-source clusters do not.

### 4. Candidate incident formation
For each surviving cluster, emit:
```json
{
  "agent": "fusion-agent",
  "candidate_id": "cand_<uuid>",
  "zone": "...",
  "centroid": {"lat": ..., "lon": ...},
  "signal_ids": [...],
  "source_types": ["social", "weather", "traffic"],
  "diversity_score": 0.67,
  "avg_credibility": 0.74,
  "hypothesis_seed": "flood | heatwave | ...",
  "ts_first_signal": "...",
  "ts_last_signal": "...",
  "envelope": { "tier": 2, "decision": "candidate_formed", "confidence": 0.71 }
}
```

`hypothesis_seed` from keyword voting across the cluster's signals; ties broken by highest-credibility signal.

## Rules
1. Single-source clusters with credibility < 0.5 emitted as `weak_candidate`, never auto-promoted.
2. A signal can belong to at most one cluster (hard assignment by nearest centroid).
3. If a cluster's signals come from the SAME social user, it's not multi-source. Track user_id_hash dedup.

## Failure Modes
- Zero clusters: emit a `fusion:idle` artifact and exit.
- Geo-less signal flood: emit `fusion:degraded:no_geo` and continue with zone-only clustering.
