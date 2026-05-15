# Sprint Methodology — Crisis Response Multi-Agent System

## Cadence
9 sprints (Sprint 0 through Sprint 8). Each sprint is a self-contained, verifiable unit.

## Roles
- **Project Manager Agent (PM)** — `.agent/skills/pm/SKILL.md`
  - Reads the active sprint plan.
  - Fans out tasks to specialist skills.
  - Tracks follow-ups in `sprints/progress.md`.
  - Invokes the Verifier Agent at sprint end.
  - Produces a Sprint Completion Artifact (`sprints/completed/sprint-N.json`).
- **Verifier Agent** — `.agent/skills/verifier/SKILL.md`
  - Reads acceptance criteria from the sprint plan.
  - Walks every artifact and checks each criterion.
  - Returns `pass` / `partial` / `fail` with reasoning and a remediation list.
  - PM cannot advance to next sprint until Verifier returns `pass`.
- **Specialist Skills** — 17 agents in `.agent/skills/<name>/`
  - Each owns one tier of the crisis pipeline.
  - Emits structured JSON artifacts under `artifacts/<run-id>/<tier>/`.

## Sprint Lifecycle
1. **Plan** — PM reads `sprints/sprint-N-*.md`, extracts tasks, sets owners.
2. **Execute** — Specialist skills run in parallel where possible, sequentially where dependent.
3. **Verify** — Verifier walks acceptance criteria.
4. **Retro** — PM appends lessons to `sprints/progress.md`.
5. **Sign-off** — Sprint completion artifact written; next sprint marked `unblocked`.

## Acceptance Criteria Conventions
Every sprint plan ends with a `## Acceptance Criteria` section. Each line is `[ ]` and machine-checkable:
- `file_exists:<path>` — file must exist and be non-empty
- `schema_valid:<path>:<schema>` — JSON/YAML must conform
- `test_passes:<command>` — shell command exit 0
- `artifact_present:<glob>` — at least one matching artifact
- `manual_review:<checklist>` — explicit human checklist

## Artifact Discipline
All agent outputs are JSON with this envelope:
```json
{
  "agent": "<name>",
  "skill_version": "<semver>",
  "run_id": "<uuid>",
  "ts": "<iso8601>",
  "tier": "<1-7>",
  "inputs_summary": {...},
  "evidence": [...],
  "hypothesis": "...",
  "confidence": 0.0-1.0,
  "decision": "...",
  "alternatives_considered": [...],
  "next_action": "...",
  "side_effects": [...]
}
```
This envelope is what makes Antigravity traces legible to judges.

## Follow-up Discipline
PM logs every blocker, deferred decision, and known-unknown in `sprints/progress.md` under the active sprint section. No silent skips.
