# Limitations

## What this hackathon build is NOT
- A production-ready early warning system. It is a working multi-agent prototype with deterministic scenarios.
- A real X/Twitter ingester — we use a synthetic JSON stream because the real firehose is not available without paid access. The `social-agent` is structurally identical, so swap-in is a one-line adapter change.
- A real SMS gateway — alerts terminate at FCM topics. Pakistani last-mile delivery would integrate with Jazz/Telenor APIs.
- A real OAuth2 system — auth is mock OTP for the demo.

## Known caveats
- **Geo accuracy** depends on user GPS. A 100m miss on a citizen report can cluster into the wrong sector. Mitigation: we already require `accuracy_m` ≤ 100 before accepting; otherwise the user is prompted to drop a pin.
- **Severity rubric** is conservative on rare/long-tail crises (e.g., disease cluster). It defaults to "monitor only" rather than dispatch unless multi-source corroboration is strong.
- **Hungarian allocator** assumes fungible assets within a capability tag — it does not model fatigue, weather conditions, or political constraints (e.g., a rescue team that won't enter a particular zone).
- **Forecast Monte Carlo** uses simple analytic distributions. For floods specifically, a hydrological model would be much better.
- **Source trust adjustments** are conservative (α=0.05, β=0.10). It will take ~50 confirmed reports for a new citizen to reach trust 0.85.
- **Public alert language** — Urdu translation uses a glossary mock when GEMINI_API_KEY is unset. Production would route through a verified translator pipeline before sending.

## Things we deliberately punted
- Differential privacy on the aggregate dashboards.
- Federated learning across cities.
- A formal proof of correctness for the recovery loop (audit consistency).
- Realtime Pakistan-government API integrations (NDMA, PDMA, Rescue 1122).
- Voice-call ingestion (we accept transcripts but do not transcribe live audio).

## What would change in production
1. Replace mock OTP with proper auth (OAuth2 + device binding).
2. Add rate limits per IP / user / asset.
3. Move SQLite → Postgres + per-city sharding.
4. Replace in-process TraceBus with Redis Streams.
5. Add a security review of the Antigravity Skill discovery surface (skills can run shell — production would sandbox).
6. Build a real time-series store for sensor history (currently a 1h ring buffer in memory).
