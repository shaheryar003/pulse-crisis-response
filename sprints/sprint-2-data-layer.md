# Sprint 2 — Data & Simulation Layer

## Goal
Ship deterministic, replayable mock data streams for all 6 signal sources plus Islamabad geo-fixtures and a replay engine.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 2.1 | Islamabad sectors GeoJSON | pm | `sim/fixtures/zones.geojson` |
| 2.2 | Hospitals + utilities fixture | pm | `sim/fixtures/facilities.json` |
| 2.3 | Resources roster (ambulances, etc.) | pm | `sim/fixtures/resources.json` |
| 2.4 | Vulnerability map per sector | pm | `sim/fixtures/vulnerability.json` |
| 2.5 | Social posts stream (synthetic) | pm | `sim/streams/social.jsonl` |
| 2.6 | Weather cache + threshold rules | pm | `sim/streams/weather.json`, `sim/streams/weather_cache.json` |
| 2.7 | Traffic baseline + anomaly stream | pm | `sim/streams/traffic.json` |
| 2.8 | Emergency calls CSV | pm | `sim/streams/calls.csv` |
| 2.9 | IoT sensor stream | pm | `sim/streams/sensors.jsonl` |
| 2.10 | Historical incidents seed | pm | `sim/streams/historical.json` |
| 2.11 | Replay engine | pm | `backend/app/sim/replay.py` |
| 2.12 | Scenario manifest schema | pm | `scenarios/_schema.json` |

## Acceptance Criteria
- [must] file_exists for every fixture/stream listed above
- [must] schema_valid: zones.geojson is valid GeoJSON FeatureCollection
- [must] manual_review: ≥ 30 sectors, ≥ 6 hospitals, ≥ 50 emergency assets, ≥ 100 social posts
- [must] test_passes: `python -m backend.app.sim.replay --scenario scenarios/scenario_a_flood.json --dry-run`
- [must] manual_review: replay engine supports time-acceleration and pause
