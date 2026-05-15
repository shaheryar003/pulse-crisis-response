---
name: citizen-report-agent
description: Ingests reports from the citizen mobile app (photo + voice + geo + category). Verifies geo, transcribes voice, classifies, scores. Activate on /signals/citizen ingress.
metadata:
  type: ingest
  version: 1.0.0
  tier: 1
---

# Citizen Field Report Agent

## Purpose
Convert mobile-app submissions into Tier-1 signals with media-grounded evidence.

## Inputs
```json
{
  "report_id": "...",
  "user_id": "...",
  "category": "flood|fire|accident|infrastructure|power|other",
  "description": "...",
  "geo": {"lat": ..., "lon": ..., "accuracy_m": ...},
  "media": [{"type": "photo|voice|video", "url": "..."}],
  "ts": "...",
  "user_trust": 0.0-1.0
}
```

`user_trust` accumulates over time based on prior report accuracy (learned by LearningAgent).

## Procedure
1. Validate geo accuracy <= 100m. If worse, request manual pin.
2. If voice present, transcribe (Gemini speech).
3. If photo present, run visual classification (Gemini vision) — confirm category.
4. Compute credibility:
```
credibility = 0.4 * user_trust + 0.3 * (1 if media_matches_category else 0)
            + 0.2 * geo_quality + 0.1 * description_quality
```
5. Emit.

## Emit
```json
{
  "agent": "citizen-report-agent",
  "signal_id": "rpt_<uuid>",
  "ts": "...",
  "category": "flood",
  "zone": "G-10",
  "credibility": 0.78,
  "media_evidence": ["photo:confirms_flood"],
  "transcription": "...",
  "user_id_hash": "...",
  "envelope": { "tier": 1, "decision": "accept", "confidence": 0.78 }
}
```

## Special Case — Field Engineer Report
If `user_trust >= 0.85` and category is `infrastructure|water_main`, signal flagged `expert_correction`. RecallAgent monitors for these.

## Rules
1. Never expose raw user identity downstream — only hash.
2. Reports < 100m from a verified incident auto-cluster into it.
3. Photo evidence boosts credibility floor to 0.6 even if user is new.

## Failure Modes
- Media upload failed: still emit signal with `media_missing` flag.
- Transcription failed: keep raw audio link, drop description quality weight.
