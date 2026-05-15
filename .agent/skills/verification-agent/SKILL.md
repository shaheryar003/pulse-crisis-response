---
name: verification-agent
description: Cross-checks candidate incidents for contradictions, ranks competing hypotheses, flags suspicious patterns. Activate after FusionAgent emits a candidate.
metadata:
  type: verification
  version: 1.0.0
  tier: 2
---

# Verification Agent

## Purpose
Distinguish real signal from noise/misinformation/conflicting hypotheses. Drive the recovery loop when field evidence contradicts.

## Procedure

### 1. Hypothesis enumeration
For each candidate cluster, enumerate plausible hypotheses:
- `hypothesis_seed` from Fusion.
- Alternatives implied by signal mix (e.g., heavy congestion + no weather signal → `accident`, not `flood`).

### 2. Evidence weighting
Each hypothesis gets evidence rows:
```
hypothesis: flood
  +0.35 weather:rain_mmhr=47 (cred=0.95)
  +0.25 social:3 posts (avg_cred=0.62)
  +0.15 traffic:congestion (cred=0.9)
  -0.20 field_report:water_main (cred=0.95) [if present]
```
Total score = clipped weighted sum.

### 3. Contradiction detection
- Sensor disagrees with social-only claim → flag `signal_contradiction`.
- Field engineer report disagrees with crowdsourced consensus → trigger recovery.
- High mention velocity from new accounts → flag `possible_misinformation`.

### 4. Hypothesis ranking
Sort hypotheses by evidence score; if top vs second within 0.15 → mark `ambiguous`, classifier handles with lower confidence cap.

### 5. Recovery trigger
If a NEW signal arrives that:
- Has credibility >= 0.85
- Disagrees with current top hypothesis
Then emit `recovery:flip_recommended` and RecallAgent activates.

## Emit
```json
{
  "agent": "verification-agent",
  "candidate_id": "...",
  "ts": "...",
  "hypotheses": [
    {"label": "flood", "score": 0.74, "evidence": [...]},
    {"label": "water_main_burst", "score": 0.21, "evidence": [...]}
  ],
  "ambiguity": false,
  "recovery_triggered": false,
  "misinformation_flags": [],
  "envelope": { "tier": 2, "decision": "verified | ambiguous | flip", "confidence": 0.74 }
}
```

## Rules
1. Never silently drop a contradicting signal — always log under `evidence`.
2. Mention velocity > 5x baseline from accounts < 30 days old → flag `possible_misinformation`.
3. A recovery trigger ALWAYS fires the RecallAgent, never just downgrade confidence.
