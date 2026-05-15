# Scalability

## Today (hackathon build)
- Single FastAPI process, SQLite, in-process trace bus.
- ~50-150 incidents per minute sustained on a laptop.
- Single command-center dashboard handles ~256 events of replay buffer.

## Path to one city (Islamabad-scale, ~200 incidents/day, 50k push/day)

1. Swap SQLite → Postgres (single-line change in `db/migrate.py`; schema is portable).
2. Move the agent pipeline from in-process to a queue (Redis Streams or Cloud Pub/Sub).
3. Run multiple Cloud Run replicas of the FastAPI service; trace bus moves to Pub/Sub.
4. FCM + an SMS provider for alert delivery.
5. Add a CDN in front of `/alerts` for the citizen app.

## Path to multi-city (Pakistan-wide, ~5k incidents/day)

1. **Sharding by city** — each city gets its own commander instance + Postgres + queue. Cross-city telemetry is best-effort.
2. **Shared services** — Antigravity Skills + LLM caches (Gemini Pro/Flash) shared via a single org-level deployment.
3. **Edge caching** — vulnerability + geo fixtures pinned to per-city edge locations.
4. **Provincial pool** — when ResourceAllocator emits `resource_shortfall`, a higher-tier coordinator can borrow units from neighbouring city pools.

## What does not scale
- Hungarian assignment is O(n³). At ~300 (rows × assets), latency stays sub-second; beyond that, switch to greedy or LP relaxation.
- The 200-sample Monte Carlo per incident is fine for ≤ 50 simultaneous incidents per round; beyond that, drop to 50 samples or precompute lookup tables.
- The trace WebSocket fan-out is in-process; for > 100 concurrent dashboard subscribers, replace with Pub/Sub or Redis pub/sub.

## Capacity planning rule of thumb
- 1 commander process @ 100% CPU = ~30 rounds/sec at 1-2 incidents per round.
- 1 LLM call (Gemini Flash) ~150 ms. To stay under 1s p95 round latency, keep ensemble votes ≤ 5.
- SQLite: hard wall at ~500 writes/sec. Postgres handles 10k/sec on modest hardware.
