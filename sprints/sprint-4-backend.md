# Sprint 4 — FastAPI Backend Service

## Goal
Wrap the agent fleet in a FastAPI service. Mobile/web clients talk to this; WebSocket streams artifact updates live.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 4.1 | FastAPI app factory + lifecycle | pm | `backend/app/main.py` |
| 4.2 | SQLite schema + migrations | pm | `backend/app/db/schema.sql`, `backend/app/db/migrate.py` |
| 4.3 | `/signals` ingest endpoint | pm | `backend/app/api/signals.py` |
| 4.4 | `/incidents` query endpoint | pm | `backend/app/api/incidents.py` |
| 4.5 | `/resources` endpoint | pm | `backend/app/api/resources.py` |
| 4.6 | `/dispatch` endpoint (responder) | pm | `backend/app/api/dispatch.py` |
| 4.7 | `/alerts` endpoint (citizen) | pm | `backend/app/api/alerts.py` |
| 4.8 | `/scenarios` (demo control) | pm | `backend/app/api/scenarios.py` |
| 4.9 | `/trace` WebSocket | pm | `backend/app/api/trace_ws.py` |
| 4.10 | Mock auth (phone OTP) | pm | `backend/app/api/auth.py` |
| 4.11 | OpenAPI generation | pm | auto |
| 4.12 | Integration tests | pm | `backend/tests/test_api_*.py` |

## Acceptance Criteria
- [must] test_passes: `pytest backend/tests/test_api_* -q` exits 0
- [must] test_passes: `python -c "from backend.app.main import app; import json; print(json.dumps(app.openapi()))"` produces valid OpenAPI 3
- [must] manual_review: WebSocket emits every agent artifact in real time
- [must] manual_review: SQLite schema includes incidents, signals, dispatches, alerts, resources, users, audit_log
- [should] manual_review: rate limiting + error envelopes consistent across endpoints
