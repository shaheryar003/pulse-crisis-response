# Pulse — Agentic Urban Crisis Response

> Multi-agent crisis detection, prediction, allocation, and recovery for Pakistani cities.
> Powered by **Google Antigravity** (Mission Control + 20 Skills), **Gemini 3** (Pro + Flash with deterministic mock fallback), and a tiered 17-specialist agent pipeline.

---

## What it does

1. **Fuses 6 signal sources** — social posts, weather, traffic, emergency calls, IoT sensors, citizen field reports — plus historical vulnerability data.
2. **Detects + classifies** crises (flood, heatwave, water main, accident, infrastructure, power, disorder, disease) with calibrated severity (1-5) and ensemble-derived confidence.
3. **Predicts evolution** — radius, population, peak time, duration, spread risk with explicit p10/p50/p90 uncertainty bands.
4. **Allocates constrained resources** across simultaneous incidents using the Hungarian bipartite matcher with explainable trade-offs.
5. **Simulates** before/after impact including side effects (congestion, evacuation jams, hospital surge).
6. **Notifies** stakeholders in 6 tailored channels including bilingual (Urdu + English) public alerts.
7. **Recovers** from false alarms via verification flips, public retraction (with strikethrough — never deleted), and audit logging.
8. **Degrades gracefully** when APIs fail — cached signals + stale-flagging.

## Antigravity integration

20 Skills orchestrated through Antigravity Mission Control:
- 3 meta — `pm`, `verifier`, `commander`
- 6 Tier-1 ingest — `social-agent`, `weather-agent`, `traffic-agent`, `sensor-agent`, `citizen-report-agent`, `historical-agent`
- 2 Tier-2 fusion — `fusion-agent`, `verification-agent`
- 1 Tier-3 classify — `classifier-agent`
- 1 Tier-4 forecast — `severity-forecaster`
- 3 Tier-5 coordinate — `prioritizer`, `resource-allocator`, `simulation-agent`
- 2 Tier-6 act — `dispatch-agent`, `stakeholder-comms`
- 2 Tier-7 recover — `recall-agent`, `learning-agent`

See [`docs/antigravity-usage.md`](docs/antigravity-usage.md).

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for the Mermaid diagram and per-tier flow.

## Quickstart

### Backend
```bash
cd backend
pip install -e ".[dev]"
python -m uvicorn app.main:app --reload --port 8000
```

### Run a scenario (no live APIs needed)
```bash
python scenarios/run_demo.py --all --validate
```
Expected: A→2 incidents/10 dispatches/12 messages, B→4/18/24, C→2 recalls, D→degraded mode survives.

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```
Login with any phone number, OTP `654321`. Pick a role (citizen / responder / command). Backend default URL is `http://10.0.2.2:8000` for the Android emulator.

### Docker
```bash
docker compose -f deploy/docker-compose.yml up --build
```

### Cloud Run
```bash
gcloud builds submit --tag gcr.io/PROJECT_ID/pulse-backend
gcloud run services replace deploy/cloudrun.yaml
```

## Sprint methodology

Built sprint-by-sprint with **PM Agent + Verifier Agent** orchestration:

| Sprint | Goal | Verdict |
|---|---|---|
| 0 | Foundation: PM + Verifier + sprint methodology | pass |
| 1 | Agent fleet — 17 specialist Antigravity Skills + Commander | pass |
| 2 | Data + simulation layer (6 streams + Islamabad geo) | pass |
| 3 | Python ADK agent implementation (deployable mirror) | pass |
| 4 | FastAPI backend service with WS trace | pass |
| 5 | Flutter mobile app (3 surfaces) | pass |
| 6 | Scenarios + demo orchestrator (4 validated scenarios) | pass |
| 7 | Documentation + deployment | pass |
| 8 | Final integration + master verification | (in progress) |

Live progress: [`sprints/progress.md`](sprints/progress.md). Verdicts: [`sprints/verdicts/`](sprints/verdicts).

## Repo layout
```
.agent/skills/         # Antigravity Skills (20 total)
backend/app/agents/    # Python mirrors of each Skill
backend/app/api/       # FastAPI endpoints + WebSocket
backend/app/db/        # SQLite schema + migration + store
backend/app/sim/       # Replay engine
backend/app/services/  # Geo, loader, LLM adapter
backend/tests/         # 17 tests (10 agent + 7 API)
mobile/lib/            # Flutter app — citizen, responder, command (18 dart files)
scenarios/             # 4 scripted demo scenarios + run_demo.py
sim/fixtures/          # Islamabad geo, hospitals, resources, vulnerability
sim/streams/           # Mock signal streams (social, sensors, calls, weather, traffic, historical)
sprints/               # Plans, methodology, progress, verdicts, completed sign-offs
docs/                  # Architecture, schemas, API, privacy, cost, scalability, limitations
deploy/                # Dockerfile + docker-compose + Cloud Run config
artifacts/             # Generated agent envelopes (per run)
```

## Documentation
- [`docs/architecture.md`](docs/architecture.md) — Mermaid system diagram + tier flow.
- [`docs/data-schemas.md`](docs/data-schemas.md) — Every artifact envelope and DB schema.
- [`docs/api.md`](docs/api.md) — REST + WebSocket reference.
- [`docs/antigravity-usage.md`](docs/antigravity-usage.md) — How to use Mission Control on this project.
- [`docs/privacy.md`](docs/privacy.md) — PII handling, retraction transparency, alert gating.
- [`docs/cost-latency.md`](docs/cost-latency.md) — Round latency p50/p95 + Gemini cost projections.
- [`docs/baseline.md`](docs/baseline.md) — Comparison vs single-LLM and single-source baselines.
- [`docs/scalability.md`](docs/scalability.md) — Single-process to multi-city.
- [`docs/limitations.md`](docs/limitations.md) — What we did not ship and why.

## Demo

3-5 minute video walkthrough plays the four scenarios in sequence:
1. Scenario A: G-10 flood (multi-source corroboration → confident dispatch).
2. Scenario B: F-7 katchi heatwave concurrent (multi-crisis trade-off visible in allocator artifact).
3. Scenario C: Recovery — field engineer flips classification to water main; public alert retracted; audit chain visible.
4. Scenario D: Weather API down → cache fallback + `stale_minutes` badge on dashboard.

Recreate locally: `python scenarios/run_demo.py --all --validate`.

## License
Hackathon submission — AISEEKHO 2026.
