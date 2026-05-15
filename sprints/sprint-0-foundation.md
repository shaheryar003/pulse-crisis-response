# Sprint 0 — Foundation

## Goal
Stand up the PM/Verifier orchestration layer, sprint methodology, repo skeleton, and all sprint plans.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 0.1 | Create repo directory structure | pm | dirs |
| 0.2 | Write PM Agent skill | pm | `.agent/skills/pm/SKILL.md` |
| 0.3 | Write Verifier Agent skill | pm | `.agent/skills/verifier/SKILL.md` |
| 0.4 | Write sprint methodology | pm | `sprints/methodology.md` |
| 0.5 | Draft all 9 sprint plans | pm | `sprints/sprint-*.md` |
| 0.6 | Live progress tracker | pm | `sprints/progress.md` |
| 0.7 | Top-level README skeleton | pm | `README.md` |
| 0.8 | Verifier dry-run on Sprint 0 | verifier | `sprints/verdicts/sprint-0.json` |

## Acceptance Criteria
- [must] file_exists:`.agent/skills/pm/SKILL.md`
- [must] file_exists:`.agent/skills/verifier/SKILL.md`
- [must] file_exists:`sprints/methodology.md`
- [must] file_exists:`sprints/progress.md`
- [must] artifact_present:`sprints/sprint-*.md` (count >= 9)
- [must] file_exists:`README.md`
- [must] manual_review: PM Skill has activation triggers, procedure, output envelope, rules, failure modes
- [must] manual_review: Verifier Skill has procedure with criterion-by-criterion checking and a verdict matrix format
- [should] file_exists:`sprints/verdicts/sprint-0.json` (Verifier dry-run)
