# Sprint 3 — Python Agent Implementation

## Goal
Implement every specialist agent as a Python module. Each mirrors its SKILL.md. The Commander runs the full pipeline end-to-end and produces artifacts identical to what Antigravity would emit.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 3.1 | Base agent class + envelope | pm | `backend/app/agents/base.py` |
| 3.2 | Commander orchestrator | pm | `backend/app/agents/commander.py` |
| 3.3 | All 6 Tier-1 ingest agents | pm | `backend/app/agents/ingest/*.py` |
| 3.4 | FusionAgent (spatiotemporal clustering) | pm | `backend/app/agents/fusion.py` |
| 3.5 | VerificationAgent (contradiction handling) | pm | `backend/app/agents/verification.py` |
| 3.6 | ClassifierAgent + ensemble confidence | pm | `backend/app/agents/classifier.py` |
| 3.7 | SeverityForecaster | pm | `backend/app/agents/severity.py` |
| 3.8 | PrioritizerAgent | pm | `backend/app/agents/prioritizer.py` |
| 3.9 | ResourceAllocator (Hungarian) | pm | `backend/app/agents/allocator.py` |
| 3.10 | SimulationAgent | pm | `backend/app/agents/simulation.py` |
| 3.11 | DispatchAgent | pm | `backend/app/agents/dispatch.py` |
| 3.12 | StakeholderCommsAgent | pm | `backend/app/agents/comms.py` |
| 3.13 | RecallAgent | pm | `backend/app/agents/recall.py` |
| 3.14 | LearningAgent | pm | `backend/app/agents/learning.py` |
| 3.15 | Gemini + mock LLM adapters | pm | `backend/app/services/llm.py` |
| 3.16 | Pytest suite | pm | `backend/tests/test_*.py` |

## Acceptance Criteria
- [must] file_exists for every module
- [must] test_passes: `pytest backend/tests -q` exits 0
- [must] test_passes: `python -m backend.app.agents.commander --scenario scenarios/scenario_a_flood.json` produces full artifact tree
- [must] manual_review: Allocator returns a feasible assignment when resources >= incidents
- [must] manual_review: Verification flips classification when field report contradicts initial hypothesis
- [should] manual_review: every agent's output validates against the envelope schema
