# Antigravity Usage

## How this project uses Antigravity

Antigravity hosts the **Project Manager + Verifier + Commander + 17 specialist Skills** (`.agent/skills/`). The Mission Control surface is where judges watch the trace; the deployable mobile-backend is a Python mirror of the same Skill specs (`backend/app/agents/`).

This dual-entry design is deliberate: every line of agent logic is reflected in both an Antigravity Skill (for the demo trace) and a Python module (for mobile-app runtime). They cannot drift because the Skill spec is the source of truth — Python tests assert behaviour against the Skill rules.

## Skill discovery

```
.agent/skills/
  pm/SKILL.md
  verifier/SKILL.md
  commander/SKILL.md
  social-agent/SKILL.md
  weather-agent/SKILL.md
  traffic-agent/SKILL.md
  sensor-agent/SKILL.md
  citizen-report-agent/SKILL.md
  historical-agent/SKILL.md
  fusion-agent/SKILL.md
  verification-agent/SKILL.md
  classifier-agent/SKILL.md
  severity-forecaster/SKILL.md
  prioritizer/SKILL.md
  resource-allocator/SKILL.md
  simulation-agent/SKILL.md
  dispatch-agent/SKILL.md
  stakeholder-comms/SKILL.md
  recall-agent/SKILL.md
  learning-agent/SKILL.md
```

Workspace-scope skills (committed to the repo). Antigravity loads them on workspace open and they appear in Mission Control's skill picker.

## How a sprint runs in Antigravity

1. Open the workspace in Antigravity.
2. From Mission Control, invoke `@pm start sprint 3`.
3. PM Skill reads `sprints/sprint-3-agents-python.md`, fans out tasks to specialists.
4. Each specialist Skill executes its part, emitting artifacts under `artifacts/<run-id>/<tier>/`.
5. PM invokes `@verifier verify sprint 3`.
6. Verifier walks acceptance criteria, writes `sprints/verdicts/sprint-3.json`, returns verdict.
7. If `pass`, PM writes `sprints/completed/sprint-3.json` and unblocks Sprint 4.

## How a crisis round runs in Antigravity

1. From Mission Control, invoke `@commander run round` (or trigger a scenario from the FastAPI dashboard).
2. Commander fans out the 6 Tier-1 ingest skills in parallel — visible in the manager surface as 6 concurrent runners with progress bars.
3. As each tier completes, Commander writes a tier-summary artifact; Mission Control's tree view shows them under the round.
4. The trace tree reads top-to-bottom: Tier 1 → 2 → 3 → 4 → 5 → 6 → 7. Each artifact is a JSON envelope (see `sprints/methodology.md`).
5. If a recovery is triggered (e.g., field engineer report contradicts), a fresh `recall-agent` artifact appears under Tier 7 with the audit chain.

## What judges should look at

- `.agent/skills/*/SKILL.md` — the Skill specs themselves, including scoring formulas with concrete coefficients (credibility, severity, priority, allocation cost).
- `artifacts/<run-id>/` after running a scenario — the full envelope tree.
- `sprints/verdicts/sprint-*.json` — verifier sign-offs with criterion-by-criterion evidence.
- The mobile Command Center's trace pane (live mirror of Antigravity Mission Control over WebSocket).

## Skills + MCP

The hackathon build does not require additional MCP servers. Production deployments would attach:
- A GitHub MCP for opening incident reports as issues.
- A PostgreSQL MCP for direct DB queries from operator chat.
- A Slack MCP for cross-team notifications.

## Switching between Antigravity-only and deployed modes

```
# Run a scenario inside Antigravity (Mission Control fan-out)
@commander run scenario A

# Run the same scenario via deployable backend
python scenarios/run_demo.py --scenario A --validate

# Run from mobile Command Center (over the FastAPI service)
POST /scenarios/A/run
```

All three paths produce identical artifact JSON.
