# Sprint 7 — Documentation + Deployment

## Goal
Ship rubric-complete documentation and deployable container artifacts.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 7.1 | README (full rubric coverage) | pm | `README.md` |
| 7.2 | Architecture diagram (Mermaid) | pm | `docs/architecture.md` |
| 7.3 | Data schemas | pm | `docs/data-schemas.md` |
| 7.4 | API reference | pm | `docs/api.md` |
| 7.5 | Privacy & safety | pm | `docs/privacy.md` |
| 7.6 | Cost & latency analysis | pm | `docs/cost-latency.md` |
| 7.7 | Baseline comparison | pm | `docs/baseline.md` |
| 7.8 | Scalability | pm | `docs/scalability.md` |
| 7.9 | Limitations | pm | `docs/limitations.md` |
| 7.10 | Antigravity usage guide | pm | `docs/antigravity-usage.md` |
| 7.11 | Dockerfile | pm | `deploy/Dockerfile` |
| 7.12 | docker-compose | pm | `deploy/docker-compose.yml` |
| 7.13 | Cloud Run config | pm | `deploy/cloudrun.yaml` |

## Acceptance Criteria
- [must] file_exists for every output
- [must] manual_review: README covers architecture, data schemas, Antigravity usage, APIs/tools, assumptions, privacy/safety, cost/latency, baseline, scalability, limitations
- [must] manual_review: architecture diagram renders in Mermaid
- [must] manual_review: Antigravity usage doc shows Skill discovery + trace screenshots references
