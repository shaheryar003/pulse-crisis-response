# Sprint 1 — Agent Fleet (17 Antigravity Skills)

## Goal
Author the full specialist agent fleet as Antigravity Skills under `.agent/skills/`. Each agent owns one tier of the crisis pipeline and emits structured artifacts.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 1.1 | Commander (Router) | pm | `.agent/skills/commander/SKILL.md` |
| 1.2 | SocialAgent (Tier 1) | pm | `.agent/skills/social-agent/SKILL.md` |
| 1.3 | WeatherAgent (Tier 1) | pm | `.agent/skills/weather-agent/SKILL.md` |
| 1.4 | TrafficAgent (Tier 1) | pm | `.agent/skills/traffic-agent/SKILL.md` |
| 1.5 | SensorAgent (Tier 1) | pm | `.agent/skills/sensor-agent/SKILL.md` |
| 1.6 | CitizenReportAgent (Tier 1) | pm | `.agent/skills/citizen-report-agent/SKILL.md` |
| 1.7 | HistoricalAgent (Tier 1) | pm | `.agent/skills/historical-agent/SKILL.md` |
| 1.8 | FusionAgent (Tier 2) | pm | `.agent/skills/fusion-agent/SKILL.md` |
| 1.9 | VerificationAgent (Tier 2) | pm | `.agent/skills/verification-agent/SKILL.md` |
| 1.10 | ClassifierAgent (Tier 3) | pm | `.agent/skills/classifier-agent/SKILL.md` |
| 1.11 | SeverityForecaster (Tier 4) | pm | `.agent/skills/severity-forecaster/SKILL.md` |
| 1.12 | PrioritizerAgent (Tier 5) | pm | `.agent/skills/prioritizer/SKILL.md` |
| 1.13 | ResourceAllocator (Tier 5) | pm | `.agent/skills/resource-allocator/SKILL.md` |
| 1.14 | SimulationAgent (Tier 5) | pm | `.agent/skills/simulation-agent/SKILL.md` |
| 1.15 | DispatchAgent (Tier 6) | pm | `.agent/skills/dispatch-agent/SKILL.md` |
| 1.16 | StakeholderCommsAgent (Tier 6) | pm | `.agent/skills/stakeholder-comms/SKILL.md` |
| 1.17 | RecallAgent (Tier 7) | pm | `.agent/skills/recall-agent/SKILL.md` |
| 1.18 | LearningAgent (Tier 7) | pm | `.agent/skills/learning-agent/SKILL.md` |

## Each SKILL.md must contain
1. Frontmatter (`name`, `description`, `metadata.type`, `metadata.version`, `metadata.tier`).
2. Purpose + activation triggers.
3. Inputs (signal schema, upstream agents).
4. Procedure (numbered steps, including decision logic and scoring formulas where applicable).
5. Output envelope (extends the standard envelope with tier-specific fields).
6. Rules + failure modes.
7. At least one worked example.

## Acceptance Criteria
- [must] artifact_present:`.agent/skills/*/SKILL.md` (count == 20: 17 specialists + pm + verifier + commander)
- [must] schema_valid: every SKILL.md frontmatter has `name`, `description`, `metadata.type`, `metadata.version`
- [must] manual_review: every specialist SKILL specifies its output envelope schema
- [must] manual_review: Commander explains routing logic for each tier
- [must] manual_review: scoring formulas (credibility, severity, allocation cost) appear with concrete coefficients
- [should] manual_review: each SKILL has a worked example
