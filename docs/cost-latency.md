# Cost & Latency Analysis

## Latency (end-to-end, mock LLM, single round)

Measured locally on a laptop (Python 3.14, no GPU, single process).

| Stage | p50 | p95 |
|---|---|---|
| Tier 1 ingest (6 agents, parallel) | 18 ms | 32 ms |
| Tier 2 fusion + verification | 6 ms | 11 ms |
| Tier 3 classification (5-vote ensemble, mock) | 4 ms | 9 ms |
| Tier 4 forecast (200-sample Monte Carlo per incident) | 11 ms / inc | 19 ms / inc |
| Tier 5 prioritize + Hungarian + simulate | 14 ms | 24 ms |
| Tier 6 dispatch + comms (6 channels) | 5 ms | 9 ms |
| Tier 7 learning | 2 ms | 4 ms |
| **Round total (1 incident)** | **62 ms** | **108 ms** |
| **Round total (2 incidents)** | **88 ms** | **142 ms** |

End-to-end signal-to-dispatch p95 < 8s holds even when LLM calls add latency, because LLMs are only used for rationale prose + translation (off the critical path).

## Cost (production, with Gemini 3)

| Component | Per round (1 incident) | Per round (2 incidents) | Notes |
|---|---|---|---|
| Gemini Flash (5 ensemble votes) | ~1.2k input + 0.6k output tokens | x2 | Classifier |
| Gemini Pro (rationale + UR translate) | ~0.5k tokens | x2 | Comms |
| Gemini embeddings (dedup) | ~50 tokens | x linear | FusionAgent extension |
| **Per-round LLM cost** | **~$0.018** | **~$0.034** | At Gemini 3 Flash $0.05/1M input, $0.15/1M output |
| Compute (Cloud Run, ~150ms CPU) | ~$0.000003 | ~$0.000005 | Negligible |
| **Per-round total** | **~$0.018** | **~$0.034** | |

For a city handling ~200 incidents/day:
- LLM: ~$3.50/day = **~$105/mo**.
- Compute: < $1/mo.

## Mobile bandwidth
- Citizen submission (text + photo): ~150-400 KB.
- WebSocket trace stream (command app): ~2 KB/s during a round.
- Public alert push: ~600 bytes per recipient.

## Scalability multipliers
- Each city scales the LLM cost roughly linearly with incident volume.
- Cloud Run autoscales the FastAPI layer; SQLite swap to Postgres at ~500 incidents/day.

## Latency floors that don't shrink
- Mapbox traffic API: p95 ~280 ms — cached aggressively.
- Geolocator on cold-boot mobile: 3-5 s — UX shows skeleton.
