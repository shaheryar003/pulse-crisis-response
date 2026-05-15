# Sprint 8 — Final Integration + Master Verification

## Goal
Verify the entire system end-to-end against every rubric line item. Bug bash. Polish.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 8.1 | E2E dry-run all scenarios | verifier | `sprints/verdicts/e2e.json` |
| 8.2 | Master rubric verifier | verifier | `sprints/verdicts/rubric.json` |
| 8.3 | Performance check (p95 latency) | pm | `docs/perf-report.md` |
| 8.4 | Bug bash log | pm | `sprints/progress.md` (appended) |
| 8.5 | Demo dry-run | pm | `sprints/verdicts/demo.json` |

## Acceptance Criteria
- [must] manual_review: master verifier covers all 6 rubric criteria
- [must] manual_review: every scenario runs without manual intervention
- [must] manual_review: p95 incident-to-dispatch < 8s in mock mode
- [must] manual_review: demo dry-run produces all required visual artifacts within 5 min
