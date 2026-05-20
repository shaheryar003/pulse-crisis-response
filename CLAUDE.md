# Pulse — Project Memory

> Read this on every new Claude session. It is the single source of truth for what this project is, how it is structured, and how to work on it.

## What this is
**Pulse** is a multi-agent urban crisis response system for Pakistani cities, built for the AISEEKHO 2026 hackathon. It uses Google Antigravity Skills to orchestrate 17 specialist crisis agents (plus a PM + Verifier + Commander + 4 UI/UX meta skills), exposes them through a FastAPI backend, and surfaces them through a Flutter mobile app with three role-based surfaces: **Citizen**, **Responder**, **Command Center**.

## How it was built
9 sprints with **PM Agent + Verifier Agent** orchestration. Every sprint has:
- A plan in `sprints/sprint-N-*.md` with machine-checkable acceptance criteria
- A verdict in `sprints/verdicts/sprint-N.json`
- A close-out in `sprints/completed/sprint-N.json`
- All 9 sprints currently **pass**.

Master rubric verdict lives at `sprints/verdicts/rubric.json` — `strong` on all 6 hackathon scoring dimensions.

## Architecture at a glance
```
.agent/skills/    24 Antigravity Skills (pm, verifier, commander + 17 specialists + 4 UI/UX meta)
backend/app/      Python mirror of every skill + FastAPI + SQLite + WebSocket /trace
mobile/lib/       Flutter app (3 surfaces, dark "Tactical Humanitarian" design system)
sim/              Islamabad geo fixtures + 6 mock signal streams
scenarios/        4 deterministic demo scenarios (A/B/C/D) + run_demo.py
sprints/          Plans, verdicts, completed sign-offs, progress tracker
docs/             Architecture, schemas, API, privacy, cost, baseline, scalability, limits
deploy/           Dockerfile + docker-compose + Cloud Run manifest
```

## Run it locally
```bash
# Backend
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000

# Mobile (Flutter web — recommended for demo)
cd mobile && flutter run -d chrome --web-port 5000 --web-hostname localhost

# Tests
python -m pytest backend/tests -q                       # 17/17

# Validate all 4 scenarios end-to-end
python scenarios/run_demo.py --all --validate           # 4/4 ok
```

Demo login: any phone, OTP `654321`, pick a role.
On web, API base auto-defaults to `http://localhost:8000` (see `mobile/lib/shared/auth.dart`).
On Android emulator, defaults to `http://10.0.2.2:8000`.

## Agent topology (7 tiers)
1. **Ingest** — social, weather, traffic, sensor, citizen-report, historical (parallel)
2. **Fusion** — fusion-agent (spatiotemporal clustering), verification-agent (contradictions + recovery trigger)
3. **Classify** — classifier-agent (5-vote ensemble, calibrated severity)
4. **Forecast** — severity-forecaster (200-sample Monte Carlo, p10/p50/p90)
5. **Coordinate** — prioritizer, resource-allocator (Hungarian), simulation-agent
6. **Act** — dispatch-agent, stakeholder-comms (6 channels, bilingual EN+UR)
7. **Recover** — recall-agent (audit log + retraction), learning-agent

The Commander (`backend/app/agents/commander.py`) is the orchestrator that runs all 7 tiers. Every agent emits a standardized **envelope** JSON to `artifacts/<run-id>/<tier>/` (see `sprints/methodology.md`).

## The four scenarios (canonical demos)
| ID | Name | What it proves |
|---|---|---|
| A | G-10 urban flooding | Multi-source corroboration → confident dispatch |
| B | F-7 katchi heatwave (concurrent) | Multi-crisis prioritization + Hungarian trade-off |
| C | Recovery flip (flood → water main) | Expert correction + audit chain + public retraction |
| D | Degraded mode (weather API down) | Fallback cache + `stale_minutes` flag |

All four validate green via `python scenarios/run_demo.py --all --validate`.

## Mobile design language: "Tactical Humanitarian"
- **Aesthetic**: dark slate operations dashboard with editorial Fraunces italic display, DM Sans body, JetBrains Mono data, Noto Nastaliq Urdu for Pakistani public alerts.
- **Tokens** live in `mobile/lib/shared/tokens.dart` — `PulseColors`, `PulseRadii`, `PulseSpace`.
- **Theme** built in `mobile/lib/shared/theme.dart` — hand-rolled `ColorScheme`, not seed-color generator.
- **Widget library** in `mobile/lib/shared/widgets/`:
  - `SeverityPill` — square 24×24 with mono numeral, 1px outline, sev 4+ pulses
  - `StatusPill` — 3px leading colored bar + label, NOT rounded-full
  - `IncidentCard` — sharp corners, dot-leader rows, confidence sparkbar
  - `TraceEventCard` — the Command Center showpiece (tier badge + agent + ms timestamp + decision)
  - `DotLeader` — label · · · · · value with CustomPaint dot leader
  - `Sparkbar` — 10-cell mini bar chart
  - `UtilBar` — fixed top utility bar, not Material AppBar
  - `MapPin` — circular numeric badge with pulsing halo for sev 4+
  - `SindhTile` — subtle 8-point star motif (used 4% opacity, twice per screen max)
  - `CtaButton` — `▸ LABEL` outlined teal CTA
- **Map tiles**: CartoDB dark (`https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png`). NOT default OSM.
- **String catalog** lives in `mobile/lib/shared/strings.dart` — `PulseStrings.get(key, locale)`. All user-visible strings (EN + UR) must be in this catalog; do not hardcode in widget files.

## Backend conventions
- **All agents are offline-deterministic by default.** LLM (Gemini Flash) is a mock unless `GEMINI_API_KEY` is set — see `backend/app/services/llm.py`. This makes tests reproducible and the demo network-independent.
- **Pure-Python point-in-polygon** in `backend/app/services/geo.py`. Do not reintroduce a shapely dependency — it broke once.
- **SQLite is the only DB.** Swap-in for Postgres is a one-line change; schema is portable. Audit log is APPEND-ONLY (never DELETE).
- **WebSocket `/trace`** is the live artifact stream; consumed by the Command Center surface in the mobile app.

## Conventions / gotchas
- The recall path needs `recovery_field_reports` (not `citizen_reports`) to fire the visible flip + audit chain. The `/scenarios/{id}/run` endpoint and `scenarios/run_demo.py` both route `field_report` events that way — keep them in sync.
- Severity 5 with 78k+ population is normal for G-10 floods. Scenario A's expected band is `severity_min: 4, severity_max: 5`.
- Expert correction in `verification-agent` bumps target hypothesis by +1.5 * cred AND multiplies competing hypotheses by 0.35 — both are required, otherwise the flip won't overcome accumulated initial evidence. Don't undo this.
- `flutter_lints 4` rejected `CardTheme` — use `CardThemeData`. Already fixed.
- Flutter web hot reload does NOT pick up MaterialApp root changes. After editing `main.dart`, kill and restart `flutter run` (not just press `r`).
- `mobile/web/` is generated by `flutter create . --platforms=web`. Don't put it in `.gitignore` if you want others to build it without rerunning that command.

## Where things are documented
- `README.md` — top-level overview + quickstart
- `docs/architecture.md` — Mermaid diagram + tier flow
- `docs/data-schemas.md` — every artifact envelope + DB schema
- `docs/api.md` — REST + WS reference
- `docs/antigravity-usage.md` — how Mission Control surfaces this project
- `docs/privacy.md` — PII handling, retraction transparency, alert gating
- `docs/cost-latency.md` — p50/p95 latency + Gemini cost projections
- `docs/baseline.md` — vs single-LLM + Twitter-only + sensor-only
- `docs/scalability.md` — hackathon → city → multi-city
- `docs/limitations.md` — honest limits, what we punted

## Working with this repo
- Use the **PM Agent** to drive sprint-level work (`@pm start sprint N`). Acceptance criteria are machine-checkable.
- Use the **Verifier Agent** to sign off (`@verifier verify sprint N`). It produces a verdict JSON with evidence.
- Don't bypass acceptance criteria. If something fails, fix it or document remediation; don't lower the bar.
- Every artifact is JSON with the envelope schema in `sprints/methodology.md`. New agents must conform.
- The repo is the source of truth, not memory. When in doubt, read the file.

## UI/UX meta skills (Sprint 9+)
Four skills handle the design-integrity and implementation loop. Always run auditors before `@flutter-dev`.

| Skill | Type | Purpose | Invoke when |
|---|---|---|---|
| `@ux-auditor` | auditor | Scans every Dart file for token violations, hardcoded values, missing states | Start of any UI sprint; re-run after `@flutter-dev` closes tasks |
| `@a11y-checker` | auditor | WCAG contrast, Semantics coverage, 48dp touch targets, RTL focus order | Alongside `@ux-auditor`; any sprint touching Citizen or Command screens |
| `@i18n-agent` | auditor | Owns EN+UR string catalog, enforces Noto Nastaliq + RTL, gates `@stakeholder-comms` alerts | Before any text-bearing screen ships; when `@stakeholder-comms` emits new alert copy |
| `@flutter-dev` | implementer | Implements fixes from audit reports — token subs, Semantics, RTL, new widgets | After audit reports are complete; never before |

**Correct execution order for any UI change:**
```
@ux-auditor + @a11y-checker + @i18n-agent (parallel)
  → @flutter-dev (implements all findings)
    → @ux-auditor (re-scan, confirms zero P1 violations)
      → @commander (full scenario A/B/C/D dry-run)
        → @verifier (sprint sign-off)
```
