# Sprint 9 — UI/UX Polish & Data Completeness

## Goal
Close all P1 UI/UX violations identified in the post-Sprint-8 audit;
surface the rich agent data the backend already produces but the UI ignores;
establish the missing strings catalog; and stub the two Sprint-5 screens that
were never built.

## Prerequisite
All four scenarios (A/B/C/D) validate green via
`python scenarios/run_demo.py --all --validate` before any code change is made.

## Tasks

| # | Task | Owner | Outputs |
|---|---|---|---|
| 9.0 | Pre-flight audit (parallel) | @ux-auditor, @a11y-checker, @i18n-agent | `artifacts/sprint9/audit/` |
| 9.1 | Touch target fixes (UtilIconButton, _ActionButton, _CategoryChip) | @flutter-dev | `util_bar.dart`, `queue.dart`, `report.dart` |
| 9.2 | Semantics on MapPin, _ActionButton, SeverityPill, _ScenarioMenu | @flutter-dev | 4 widget/screen files |
| 9.3 | Extract shared ErrorBox + add retry to alerts & queue error states | @flutter-dev | `shared/widgets/error_box.dart`, 2 screen files |
| 9.4 | Command dashboard: error visibility + WS reconnect with status badge | @flutter-dev | `command/dashboard.dart` |
| 9.5 | Dispatch model: add `destination` + actual incident severity | @flutter-dev | `models/dispatch.dart`, `responder/queue.dart` |
| 9.6 | AlertItem model: add `requiresHumanApproval` + ApprovalGateBadge widget | @flutter-dev | `models/alert.dart`, `shared/widgets/approval_gate_badge.dart` |
| 9.7 | Create `strings.dart` + migrate all hardcoded strings | @i18n-agent, @flutter-dev | `shared/strings.dart`, 9 modified files |
| 9.8 | Fix _channelAccent() to use incident type field not keyword match | @flutter-dev | `citizen/alerts.dart`, `models/alert.dart` |
| 9.9 | TraceEventCard: deduplicate Tier 1 vs Tier 6 accent colors | @flutter-dev | `shared/widgets/trace_event_card.dart` |
| 9.10 | Incident model p10/p90 bands + ForecastBands widget | @flutter-dev | `models/incident.dart`, `shared/widgets/forecast_bands.dart` |
| 9.11 | Enrich trace extraction: T5/6/7 fields (trade_offs, retraction_message_en, stale_minutes) | @flutter-dev | `command/dashboard.dart` |
| 9.12 | DegradedModeBanner widget + wire into command dashboard | @flutter-dev | `shared/widgets/degraded_mode_banner.dart` |
| 9.13 | AuditChainPanel widget + incident detail pane in command | @flutter-dev | `shared/widgets/audit_chain_panel.dart`, `command/dashboard.dart` |
| 9.14 | Stub citizen/verify.dart + responder/status.dart + wire into shells | @flutter-dev | `citizen/verify.dart`, `responder/status.dart` |
| 9.15 | Stress fixtures: empty / 1 / 20 incidents, sev 1–5, degraded mode | @simulation-agent | `artifacts/sprint9/stress-fixtures/` |
| 9.16 | Re-run ux-auditor: confirm zero P1 violations | @ux-auditor | `artifacts/sprint9/ux-auditor/post-report.json` |
| 9.17 | Validate bilingual copy + Urdu font + RTL layout | @i18n-agent, @stakeholder-comms | `artifacts/sprint9/i18n-agent/post-report.json` |
| 9.18 | Confirm audit-chain UI still correct after dashboard changes | @recall-agent | `artifacts/sprint9/recall-agent/audit-chain-check.json` |
| 9.19 | Full Scenario A+B+C+D dry-run | @commander | `artifacts/sprint9/commander/scenario-results.json` |
| 9.20 | Sprint sign-off | @verifier | `sprints/verdicts/sprint-9.json` |

## Acceptance Criteria

- [must] test_passes: `cd mobile && flutter analyze --no-pub` (zero errors)
- [must] test_passes: `python scenarios/run_demo.py --all --validate` (4/4 green)
- [must] artifact_present: `artifacts/sprint9/audit/ux-report.json`
- [must] artifact_present: `artifacts/sprint9/audit/a11y-report.json`
- [must] artifact_present: `artifacts/sprint9/audit/i18n-report.json`
- [must] artifact_present: `artifacts/sprint9/ux-auditor/post-report.json`
- [must] file_exists: `mobile/lib/shared/strings.dart`
- [must] file_exists: `mobile/lib/citizen/verify.dart`
- [must] file_exists: `mobile/lib/responder/status.dart`
- [must] manual_review: zero P1 violations in ux-auditor post-report
- [must] manual_review: zero critical findings in a11y-checker post-report
- [must] manual_review: i18n gate_status = pass for all stakeholder-comms alerts
- [must] manual_review: zero uncataloged_string violations remain
- [must] manual_review: all touch targets >= 48dp (UtilIconButton, ActionButton, CategoryChip)
- [must] manual_review: staged alerts with requires_human_approval show AWAITING APPROVAL badge
- [must] manual_review: command dashboard shows error banner + retry on network failure
- [must] manual_review: trace pane shows DISCONNECTED badge + reconnects after WS drop
- [must] manual_review: dispatch card shows destination zone/label from Tier-6 schema
- [must] manual_review: Scenario C trace shows retraction_message_en in Tier-7 event
- [must] manual_review: Scenario D shows stale_minutes + DegradedModeBanner in command
- [must] manual_review: tapping incident in command loads audit chain in AuditChainPanel
- [should] manual_review: all 3 surfaces have loading + error-with-retry + empty states
- [should] manual_review: Urdu alerts render in Noto Nastaliq Urdu with RTL layout
- [should] manual_review: incident card shows p10/p50/p90 population range in expanded mode
- [should] manual_review: all 7 trace tiers have visually distinct accent colors
- [should] manual_review: Scenario A audit chain renders with recipients_of_retraction

## Constraints (non-negotiable)
- Dark slate only — no light mode anywhere.
- All colors → PulseColors, radii → PulseRadii, spacing → PulseSpace.
- CardThemeData (not CardTheme) for flutter_lints 4.
- CartoDB dark tiles only — not OSM. Any new map in verify.dart uses the same urlTemplate.
- No shapely dependency — pure-Python geo only (backend); zone lookup via _zoneCoords maps (mobile).
- Audit log is read-only — AuditChainPanel has zero edit/delete affordances.
- recovery_field_reports key must not be renamed.
- After any main.dart edit: full `flutter run` restart required (not hot reload).
- SindhTile: max opacity 0.04, max once per screen.
