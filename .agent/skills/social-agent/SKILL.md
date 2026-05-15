---
name: social-agent
description: Ingests social media posts (X/Twitter, Facebook, local platforms), extracts crisis-related signals with geolocation and credibility scoring. Emits Tier-1 signal artifacts. Activate on /signals/social ingress or scenario tick.
metadata:
  type: ingest
  version: 1.0.0
  tier: 1
---

# Social Media Signal Agent

## Purpose
Convert raw social posts into structured, credibility-scored signals.

## Inputs
JSON lines, each with: `id, text, user_id, user_followers, user_verified, account_age_days, geo {lat, lon, source}, ts, lang, media_urls[]`.

## Procedure

### 1. Filter for crisis keywords (per-language)
- English: flood, fire, accident, blackout, traffic jam, riot, water main, gas leak, ambulance.
- Urdu: سیلاب، آگ، حادثہ، بلیک آؤٹ، ٹریفک، جلسہ، پانی، گیس
- Roman Urdu: sailab, aag, hadsa, gas leak, paani.

### 2. Geolocation
- If `geo.source == "gps"` → confidence 1.0.
- If place name parsed from text matches a known sector → 0.6.
- If inferred from `user_home_city` → 0.3.
- Else → 0.0, exclude from clustering.

### 3. Credibility Score
```
credibility = 0.25 * verified
            + 0.20 * min(1, log10(followers + 1) / 6)
            + 0.15 * min(1, account_age_days / 365)
            + 0.20 * geo_confidence
            + 0.10 * urgency_lang_score
            - 0.20 * contradiction_with_higher_cred
```
- `urgency_lang_score`: 0.0–1.0, presence of action words (help, urgent, emergency).
- Score in [-0.20, 1.00], clipped to [0, 1].
- Below 0.35 → tagged `unverified`, surfaces for crowd verification.

### 4. Emit artifact
```json
{
  "agent": "social-agent",
  "signal_id": "soc_<uuid>",
  "ts": "...",
  "source_post_id": "...",
  "lang": "ur|en|ur-roman",
  "geo": {"lat": ..., "lon": ..., "confidence": ...},
  "zone_match": "G-10|F-7|...",
  "keywords": ["flood", "ambulance"],
  "urgency": 0.0-1.0,
  "credibility": 0.0-1.0,
  "media_attached": true|false,
  "raw_text": "...",
  "envelope": { "agent": "social-agent", "tier": 1, "decision": "accept|unverified|drop", "confidence": ... }
}
```

## Rules
1. Drop signals with credibility < 0.15 (noise).
2. Tag `unverified` for [0.15, 0.35); pass forward with explicit flag.
3. Never silently merge; let FusionAgent cluster.
4. Strip PII (handles, names) before forwarding raw_text — store hash for traceability.

## Failure Modes
- API rate-limit: queue, emit `degraded` artifact every 60s of stall.
- Lang detection failure: fall back to English keyword set; tag `lang_unknown`.
- No geo: route to `pending_verification` queue; never enter clustering.
