# Privacy & Safety

## What we don't store
- Phone numbers in plaintext (only SHA-256 hashes).
- Social post handles or display names — only hashed user IDs.
- Citizen-report user identity — only `user_id_hash` is forwarded past Tier 1.

## Data retention
- Signals retained 30 days for forensics; auto-pruned beyond.
- Incidents retained indefinitely (anonymized via the hashing rules above).
- Audit log is append-only and never pruned — it is the system of record for retractions.

## Public alerts gating
- Any public push message whose classification confidence is below 0.65 is set to `requires_human_approval: true` and held until a human signs off.
- Alerts that would reach > 50,000 recipients require simulation review (`requires_staging` checked) before send.

## Misinformation handling
- Posts with credibility < 0.35 are tagged `unverified` and never auto-promote into the consensus path.
- Mention velocity > 5x baseline from accounts < 30 days old triggers `possible_misinformation:new_account_velocity` flag and the operator dashboard surfaces the cluster for review.

## Retraction transparency
- Public alerts that turn out to be false **are not deleted** — the citizen app keeps them visible with strikethrough and a correction. This is a deliberate trust-preservation choice.
- Audit log entries record the responsible agent chain and the user-impact (recipient count, responders recalled).

## Operator authority
- Classifier output is advisory until a human operator at the command center confirms or overrides it. The mobile app shows `requires_human_approval` badges on staged alerts.
- Operator overrides feed back into the LearningAgent as ground truth (trust = 1.0).

## Failure-mode safety
- API outages degrade with `stale_minutes` annotation; the system never silently uses stale data.
- A weather blackout emits an explicit `weather:blackout` signal so the command center knows the gap exists.
- A sensor offline > 5 min produces a `sensor:silent` artifact.

## Out-of-scope (would address before production)
- No real SMS gateway — for production, integrate with Pakistan's local SMS providers + USSD fallback for non-smartphone users.
- No formal differential-privacy guarantee on the aggregate analytics — would add Laplace noise to public dashboards.
- No personally signed JWT — the demo uses a synthetic token; production would deploy proper OAuth2 / mTLS.
