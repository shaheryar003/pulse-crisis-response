# API Reference

Base URL (default dev): `http://localhost:8000`. OpenAPI auto-generated at `/openapi.json` and Swagger UI at `/docs`.

## Auth (mock OTP)

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/otp/request` | Body: `{phone}`. In demo, OTP is `654321`. |
| POST | `/auth/otp/verify` | Body: `{phone, otp, role}`. Returns `{token, user_id, role}`. |

## Signals (ingest)

| Method | Path | Notes |
|---|---|---|
| POST | `/signals/citizen` | Citizen field report — runs through Tier-1 immediately. |
| POST | `/signals/social` | Submit a social post (used by dev tooling). |

## Incidents

| Method | Path | Notes |
|---|---|---|
| GET | `/incidents?status=active&zone=G-10` | List incidents |
| GET | `/incidents/{id}` | Detail + full audit trail |

## Resources

| Method | Path | Notes |
|---|---|---|
| GET | `/resources` | Asset roster (60 assets across 9 capability types) |

## Dispatch (responder app)

| Method | Path | Notes |
|---|---|---|
| GET | `/dispatch/queue?asset_id=X` | Pending dispatches for one asset |
| POST | `/dispatch/{id}/ack` | Responder acknowledges |
| POST | `/dispatch/{id}/status` | Body: `{status: en_route\|on_scene\|clear}` |

## Alerts

| Method | Path | Notes |
|---|---|---|
| GET | `/alerts?incident_id=...&status=...` | Public alerts (with retraction history) |

## Scenarios (demo control)

| Method | Path | Notes |
|---|---|---|
| GET | `/scenarios` | List available scenarios A/B/C/D |
| POST | `/scenarios/{id}/run` | Run scenario through full pipeline; persists incidents, dispatches, alerts; emits artifacts onto WS bus |

## Trace (WebSocket)

`ws://localhost:8000/trace` — every agent artifact arrives as a JSON message in real time. Replay buffer: 256 events.

Each frame:
```json
{"type": "artifact" | "signal", "payload": <agent_envelope_or_artifact>}
```

## Health

`GET /health` → `{"status": "ok"}`.
