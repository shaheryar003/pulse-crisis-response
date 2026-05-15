---
name: stakeholder-comms
description: Generates tailored messages for 6 channels per incident — public (bilingual), hospital, utility, traffic-police, media, command-center. Activate after Simulator approves.
metadata:
  type: comms
  version: 1.0.0
  tier: 6
---

# Stakeholder Communications

## Channels
| Channel | Format | Audience | Length |
|---|---|---|---|
| public_push | bilingual short alert | citizens in affected radius | ≤ 140 chars per language |
| hospital | clinical, triage-coded | trauma centers in radius | ≤ 600 chars |
| utility | ops escalation | WASA / IESCO / SNGPL | ≤ 400 chars |
| traffic_police | rerouting plan | ITP, motorway police | ≤ 400 chars |
| media | factual paragraph | press / PR | 1 paragraph |
| command_center | full JSON | internal | machine-readable |

## Public push templates (Urdu + English)
- Flood: "⚠️ Flooding reported in {sector}. Avoid {road}. Move to higher ground. Helpline: 1122. / ⚠️ {sector} میں سیلاب۔ {road} سے گریز کریں۔ ہیلپ لائن: 1122۔"
- Heatwave: "🥵 Heat alert {sector}. Stay indoors 11am–4pm. Hydrate. Cooling center at {address}."

## Procedure
1. For each incident in the current round, generate 6 messages using templates + slot-fill from incident JSON.
2. Translate to Urdu via Gemini (verified glossary for crisis terms).
3. For `public_push` with simulator-flagged `requires_staging`, generate 3 batches with 10-min intervals and different geographic concentric rings.
4. For `media`, never include unverified accusations; cite source counts only.

## Emit (one per channel per incident)
```json
{
  "agent": "stakeholder-comms",
  "incident_id": "...",
  "ts": "...",
  "channel": "public_push",
  "lang": "en|ur|both",
  "body": "...",
  "delivery": {"target_radius_km": 2.0, "estimated_recipients": 28000, "staged": false},
  "envelope": { "tier": 6, "decision": "drafted", "confidence": 0.9 }
}
```

## Rules
1. Public alerts with confidence < 0.65 require human approval — set `requires_human_approval: true`.
2. Never include personally identifying info from citizen reports in public messages.
3. Always include helpline + cooling-center/shelter address where applicable.
4. Media releases get a 5-min hold for command-center review.
