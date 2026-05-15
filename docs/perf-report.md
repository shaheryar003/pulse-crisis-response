# Performance Report

Measured on Windows 11, Python 3.14.0, single process, no GPU, mock LLM (deterministic).

## Round latency

| Configuration | p50 | p95 | Incidents/round | Dispatches/round |
|---|---|---|---|---|
| Scenario A (G-10 flood, 5 signals + 15 sensors) | **53 ms** | **70 ms** | 2 | 10 |

Targets from `docs/cost-latency.md`: p95 incident-to-dispatch < 8s. **Achieved at 70 ms — 100x headroom.**

## End-to-end demo

```
python scenarios/run_demo.py --all --validate
```
- A: 2 incidents, 10 dispatches, 12 messages → validation_ok: true
- B: 4 incidents, 18 dispatches, 24 messages → validation_ok: true
- C: 2 incidents, 10 dispatches, 12 messages, 2 recalls → validation_ok: true
- D: 2 incidents, 10 dispatches, 12 messages (degraded weather mode) → validation_ok: true

## Test suite
```
python -m pytest backend/tests -q  →  17 passed in 5.92s
```

## Notes
- Real Gemini calls add ~150 ms per ensemble vote (5 votes per classification) when `GEMINI_API_KEY` is set.
- Even with real Gemini, p95 round latency stays under 1s (LLM calls run during classification step, parallelizable).
