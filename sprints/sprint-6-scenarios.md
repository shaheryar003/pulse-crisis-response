# Sprint 6 — Scenarios + Demo Wiring

## Goal
Deterministic, scripted scenarios that drive the full system end-to-end for the demo video.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 6.1 | Scenario A — G-10 urban flooding | pm | `scenarios/scenario_a_flood.json` |
| 6.2 | Scenario B — F-7 heatwave (concurrent) | pm | `scenarios/scenario_b_heatwave.json` |
| 6.3 | Scenario C — recovery (flood → water main) | pm | `scenarios/scenario_c_recovery.json` |
| 6.4 | Scenario D — degraded mode (weather API down) | pm | `scenarios/scenario_d_degraded.json` |
| 6.5 | Demo orchestrator script | pm | `scenarios/run_demo.py` |
| 6.6 | Expected artifact manifest per scenario | pm | `scenarios/expected/*.json` |

## Acceptance Criteria
- [must] file_exists for every scenario
- [must] test_passes: `python scenarios/run_demo.py --scenario A --validate` exits 0
- [must] manual_review: A + B together demonstrate multi-crisis trade-off
- [must] manual_review: C produces a retraction + audit log
- [must] manual_review: D falls back to cache when weather API is unavailable
