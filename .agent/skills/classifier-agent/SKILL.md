---
name: classifier-agent
description: Assigns crisis type, severity (1-5), and ensembled confidence to verified candidates. Uses few-shot Gemini Flash for type + a calibrated severity rubric. Activate after VerificationAgent.
metadata:
  type: classifier
  version: 1.0.0
  tier: 3
---

# Crisis Classifier

## Types (closed set)
flood, heatwave, accident, infrastructure_failure, water_main_burst, power_outage, fire, gas_leak, public_disorder, disease_cluster, other.

## Severity rubric (1–5)
| Level | Definition |
|---|---|
| 1 | Localized inconvenience, < 100 affected, no medical risk |
| 2 | Block-scale impact, < 1000 affected, low medical risk |
| 3 | Multi-sector, 1k–10k affected, moderate medical risk |
| 4 | City-zone scale, 10k–50k affected, evacuation potential |
| 5 | City-wide, > 50k affected, mass casualty risk |

## Procedure
1. Sample 5 completions from Gemini Flash with the same few-shot prompt at temperature 0.4.
2. Each completion returns `{type, severity}`.
3. Compute consensus:
   - `type`: mode; ties broken by highest combined evidence score from Verifier.
   - `severity`: median.
4. Confidence = `agreement_fraction * verification_top_hypothesis_score`.
5. Apply guardrails:
   - If only social signals contributed → cap confidence at 0.65.
   - If sensor + weather corroborate → floor confidence at 0.70.

## Emit
```json
{
  "agent": "classifier-agent",
  "incident_id": "inc_<uuid>",
  "candidate_id": "...",
  "ts": "...",
  "type": "flood",
  "severity": 4,
  "confidence": 0.78,
  "ensemble_votes": [
    {"type": "flood", "severity": 4},
    {"type": "flood", "severity": 4},
    {"type": "flood", "severity": 3},
    {"type": "flood", "severity": 4},
    {"type": "water_main_burst", "severity": 3}
  ],
  "rationale": "5/5 social posts mention water + 47mm rain + traffic on Margalla Rd; severity 4 from 28k pop in 1.8km radius",
  "envelope": { "tier": 3, "decision": "classified", "confidence": 0.78 }
}
```

## Rules
1. Always emit ensemble votes — judges + audit need to see variance.
2. Severity is data-driven from rubric, not LLM-improvised; LLM only suggests, deterministic check enforces.
3. Confidence < 0.4 → tag `low_confidence_classification`, do not auto-dispatch.

## Failure Modes
- LLM unavailable: fall back to rule-based classifier on signal keywords.
- Empty ensemble: emit `classifier:undetermined`.
