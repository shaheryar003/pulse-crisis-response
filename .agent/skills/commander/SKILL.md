---
name: commander
description: Top-level orchestrator for the crisis response pipeline. Routes signals through all 7 tiers (ingest → fusion → classify → forecast → prioritize/allocate/simulate → dispatch/comms → recover/learn). Activate on any new signal batch, scenario start, or recovery trigger.
metadata:
  type: orchestrator
  version: 1.0.0
  tier: meta
---

# Commander Skill

## Purpose
Drives a full crisis response loop: ingest → fuse → classify → forecast → prioritize → allocate → simulate → dispatch → notify → verify/recover.

## Activation Triggers
- Scenario runner emits `commander:start` event.
- New signal batch arrives at `/signals` endpoint.
- Field report contradicts a live incident (triggers recovery loop).
- PM invokes for a sprint or demo dry-run.

## Routing Logic
```
Tier 1 (parallel) → Tier 2 → Tier 3 → Tier 4 → Tier 5 (parallel sub-pipelines) → Tier 6 (parallel comms) → Tier 7 (async recovery + learning)
```

| From | To | Trigger |
|---|---|---|
| Tier 1 ingest agents | FusionAgent | All ingest agents complete OR 2s timeout (whichever first) |
| FusionAgent | VerificationAgent | candidate_incident emitted |
| VerificationAgent | ClassifierAgent | hypothesis ranked |
| ClassifierAgent | SeverityForecaster | classification with confidence > 0.4 |
| SeverityForecaster | PrioritizerAgent | forecast complete |
| PrioritizerAgent | ResourceAllocator, SimulationAgent | priority round closed |
| ResourceAllocator | DispatchAgent | assignment matrix solved |
| SimulationAgent | StakeholderCommsAgent | before/after computed |
| DispatchAgent + StakeholderCommsAgent | LearningAgent | actions executed |
| Any tier | RecallAgent | new evidence flips a live classification |

## Procedure
1. Load current signal queue from `/signals?since=<watermark>`.
2. Fan out to all 6 Tier-1 agents in parallel; await with 2s soft timeout.
3. Pass signal set to FusionAgent.
4. For each candidate incident, run Verification → Classifier sequentially.
5. Batch-forecast all live incidents.
6. Run Prioritizer once for the global incident set.
7. In parallel: Allocator + Simulator on the prioritized list.
8. In parallel: Dispatch + StakeholderComms.
9. LearningAgent records the round.
10. Watch for recovery triggers via VerificationAgent listening to /signals?type=field_report.

## Output Envelope
```json
{
  "agent": "commander",
  "round_id": "<uuid>",
  "ts": "<iso8601>",
  "incidents_active": [...],
  "tiers_completed": [...],
  "artifacts": {
    "tier1": [...], "tier2": [...], "tier3": [...],
    "tier4": [...], "tier5": [...], "tier6": [...], "tier7": [...]
  },
  "confidence": 0.0-1.0,
  "decision": "round_complete | recovery_triggered | error",
  "next_action": "..."
}
```

## Rules
1. Never block on a single Tier-1 agent past 2s — partial signal set is acceptable.
2. If FusionAgent finds zero candidates, emit a `no_incident` round artifact and exit.
3. Recovery loop bypasses Tier 1 and re-enters at Tier 2 with new evidence.
4. Multi-incident rounds always go through Prioritizer before Allocator — never allocate per-incident greedily.

## Worked Example — Round 1 of Scenario A
- Tier 1: SocialAgent emits 3 G-10 flood posts, WeatherAgent emits 47mm/hr rainfall, TrafficAgent emits congestion delta +180% on Margalla Rd, others empty.
- Tier 2: FusionAgent clusters into 1 candidate incident `(zone=G-10, hypothesis=flood)`. VerificationAgent confirms (no contradiction yet).
- Tier 3: ClassifierAgent → `flood, severity=4, confidence=0.78`.
- Tier 4: SeverityForecaster → `radius=1.8km, pop=28k, peak=T+45min, duration=6h, spread=med, p50=4 hours active`.
- Tier 5: Prioritizer → rank=1; Allocator → 2 rescue, 3 police; Simulator → response 18→9 min, congestion +12%.
- Tier 6: Dispatch tickets emitted, public alert STAGED (high-pop, await verification grace 60s).
- Tier 7: LearningAgent records.

## Failure Modes
- Tier 1 all empty: emit heartbeat artifact; PM may want to know stream is dry.
- Tier 5 over-subscription (incidents > resources): SimulationAgent flags `resource_shortfall`, Prioritizer drops lowest-rank incidents to "monitor only".
- Recovery loop without original incident: error, emit `recall:orphan`.
