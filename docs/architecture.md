# Architecture

## High-level

```mermaid
flowchart TB
    subgraph Mobile["Mobile (Flutter)"]
      Citizen[Citizen App]
      Responder[Responder App]
      Command[Command Center]
    end

    subgraph Backend["FastAPI Backend"]
      AuthAPI[/auth/]
      SignalsAPI[/signals/]
      IncidentsAPI[/incidents/]
      DispatchAPI[/dispatch/]
      AlertsAPI[/alerts/]
      ScenariosAPI[/scenarios/]
      TraceWS[(/trace WebSocket)]
      DB[(SQLite + audit log)]
    end

    subgraph Antigravity["Antigravity Mission Control"]
      PM[PM Skill]
      Verifier[Verifier Skill]
      Commander[Commander Skill]
      subgraph Tier1["Tier 1 — Ingest"]
        Social[social-agent]
        Weather[weather-agent]
        Traffic[traffic-agent]
        Sensor[sensor-agent]
        CitizenAg[citizen-report-agent]
        Historical[historical-agent]
      end
      subgraph Tier2["Tier 2 — Fusion"]
        Fusion[fusion-agent]
        Verify[verification-agent]
      end
      subgraph Tier3["Tier 3 — Classify"]
        Classifier[classifier-agent]
      end
      subgraph Tier4["Tier 4 — Forecast"]
        Severity[severity-forecaster]
      end
      subgraph Tier5["Tier 5 — Coordinate"]
        Prioritizer[prioritizer]
        Allocator[resource-allocator]
        Sim[simulation-agent]
      end
      subgraph Tier6["Tier 6 — Act"]
        Dispatch[dispatch-agent]
        Comms[stakeholder-comms]
      end
      subgraph Tier7["Tier 7 — Recover"]
        Recall[recall-agent]
        Learning[learning-agent]
      end
    end

    Citizen --> SignalsAPI
    Responder --> DispatchAPI
    Command --> ScenariosAPI
    Command -.WS.-> TraceWS

    SignalsAPI --> Tier1
    Tier1 --> Tier2 --> Tier3 --> Tier4 --> Tier5
    Tier5 --> Tier6 --> Tier7
    Tier1 -.recovery.-> Tier2
    Tier6 --> DB
    Tier7 --> DB

    PM -. plans + dispatches .-> Commander
    Commander -. orchestrates .-> Tier1
    Verifier -. signs off .-> PM
```

## Data flow per round

1. **Tier 1** — six ingest agents run in parallel. Each emits a structured envelope (agent, tier, decision, confidence, evidence).
2. **Tier 2** — FusionAgent clusters by zone + geo proximity; VerificationAgent ranks hypotheses.
3. **Tier 3** — ClassifierAgent runs a 5-vote ensemble (Gemini Flash with seed jitter), returns type + severity + confidence.
4. **Tier 4** — SeverityForecaster runs 200-sample Monte Carlo on radius × duration × population, returns p10/p50/p90 bands.
5. **Tier 5** — Prioritizer ranks all live incidents; Allocator solves a Hungarian bipartite match; Simulator estimates before/after state with side effects.
6. **Tier 6** — Dispatch emits asset tickets; StakeholderComms emits 6 channel-tailored messages (public bilingual, hospital, utility, traffic-police, media, command).
7. **Tier 7** — RecallAgent handles flips; LearningAgent updates source trust scores.

## PM / Verifier loop

Every sprint follows this lifecycle:
```
PM reads sprints/sprint-N.md
    -> dispatches tasks (parallel where safe)
    -> tracks follow-ups in sprints/progress.md
    -> invokes Verifier
    -> Verifier walks acceptance criteria (file/schema/test/manual)
    -> verdict: pass | partial | fail
    -> if pass: PM writes sprints/completed/sprint-N.json + unblocks N+1
    -> if not: PM creates remediation tasks and re-runs
```

## Storage

- **SQLite** for incidents, dispatches, alerts, signals, audit_log (append-only).
- **Filesystem** for artifacts under `artifacts/<run-id>/<tier>/` so traces are inspectable without a tool.
- **In-memory pub/sub** (TraceBus) for the `/trace` WebSocket.

## LLM strategy

- All agents are deterministic by default; LLM (Gemini Flash) adds rationale prose, Urdu translation, and ensemble jitter.
- Without `GEMINI_API_KEY` the system uses an offline mock that emits fixed-jitter rationales — every test run is reproducible.
- With the env var set, the same call sites hit Gemini 3 Flash. Switching is one boolean.
