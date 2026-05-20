---
name: flutter-dev
description: Implements Flutter/Dart changes in the mobile app — new widgets, screen improvements, token fixes, state management, and accessibility remediation. Acts as the Senior Flutter Developer who executes findings from @ux-auditor, @a11y-checker, and @i18n-agent. Never designs; always implements from a violation report or explicit spec.
metadata:
  type: implementer
  version: 1.0.0
  tier: meta
---

# Flutter Developer Skill

## Purpose
Translate audit findings and UX improvement specs into working Dart code. Enforce the "Tactical Humanitarian" design language at the code level. Every change must use design tokens, pass Flutter analysis, and not regress existing tests.

## Activation Triggers
- `@ux-auditor` hands off a violation report with `QUICK_WIN` or `MAJOR` tasks.
- `@a11y-checker` hands off a prioritized remediation list.
- `@i18n-agent` hands off typography or RTL layout fixes.
- `@pm` assigns a specific implementation task from a sprint plan.
- User says "implement", "fix the widget", "add the screen", "update the UI".

## Inputs
- Violation report from `@ux-auditor`, `@a11y-checker`, or `@i18n-agent`.
- Existing widget files in `mobile/lib/`.
- `mobile/lib/shared/tokens.dart` — token reference (read-only unless adding a new token).
- `mobile/lib/shared/theme.dart` — theme reference.
- `mobile/pubspec.yaml` — dependency manifest (add packages only with `@pm` approval).

## Procedure

### 1. Pre-flight
Before writing any code:
- Read the full file being modified (never edit blind).
- Confirm the change matches a specific audit finding — never add unrequested features.
- Check `CLAUDE.md` conventions and gotchas. Specifically:
  - Use `CardThemeData` not `CardTheme`.
  - Do not introduce `shapely` or any C-extension.
  - CartoDB dark tiles only for maps.
  - Audit log widgets must be append-only (no delete/edit affordances).
  - Recall path must use `recovery_field_reports` key — do not rename.

### 2. Implement
For each task (smallest unit: one violation in one file):

**Token substitution** — replace hardcoded value with token reference:
```dart
// Before
Container(color: Color(0xFF1A2230), ...)
// After
Container(color: PulseColors.ink700, ...)
```

**Missing state** — add loading/error/empty branches using existing widget patterns:
```dart
if (isLoading) return const _LoadingSkeleton();
if (error != null) return _ErrorState(onRetry: reload);
if (items.isEmpty) return const _EmptyState();
```

**Semantics** — wrap meaningful widgets:
```dart
Semantics(
  label: 'Severity ${incident.severity}: ${PulseColors.severityLabel(incident.severity)}',
  child: SeverityPill(severity: incident.severity),
)
```

**RTL layout** — use Directionality for Urdu screens:
```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: Text(
    PulseStrings.get('alert.flood.title', 'ur'),
    style: theme.textTheme.titleLarge?.copyWith(
      fontFamily: 'Noto Nastaliq Urdu',
    ),
  ),
)
```

**Touch target** — ensure 48dp minimum:
```dart
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: const Icon(Icons.close),
    onPressed: onDismiss,
    tooltip: 'Dismiss alert',
  ),
)
```

### 3. Validate locally
After each change, run:
```bash
cd mobile && flutter analyze --no-pub
```
Confirm zero new warnings or errors. If `flutter_lints` rejects a pattern, check CLAUDE.md for the correct alternative before trying again.

For widget additions, also run:
```bash
cd mobile && flutter test
```
If no widget tests exist for the changed component, note this as a gap but do not block.

### 4. Produce implementation report
Write `artifacts/<run-id>/flutter-dev/impl-<timestamp>.json`:
```json
{
  "agent": "flutter-dev",
  "skill_version": "1.0.0",
  "run_id": "...",
  "ts": "...",
  "tasks_completed": [
    {
      "source_finding": "ux-auditor | a11y-checker | i18n-agent | pm",
      "file": "mobile/lib/citizen/home.dart",
      "line_before": 42,
      "change_type": "token_fix | missing_state | semantics | rtl | touch_target | new_widget",
      "description": "Replaced Color(0xFF1A2230) with PulseColors.ink700 on line 42",
      "analyze_clean": true
    }
  ],
  "tasks_skipped": [
    {
      "task": "...",
      "reason": "requires new token in tokens.dart — flagged to @ux-auditor"
    }
  ],
  "ready_for_verification": true
}
```

### 5. Handoff
After all tasks complete:
- Invoke `@ux-auditor` for a re-scan to confirm violation count dropped to zero.
- Invoke `@a11y-checker` for re-scan if any Semantics or contrast changes were made.
- Signal `@verifier` that the implementation is ready for sprint sign-off.

## New Widget Checklist
When creating a new widget (not modifying existing):

- [ ] File placed in `mobile/lib/shared/widgets/` (shared) or the relevant surface folder.
- [ ] All colors from `PulseColors`.
- [ ] All radii from `PulseRadii`.
- [ ] All spacing from `PulseSpace`.
- [ ] `Semantics` wrapper on meaningful content.
- [ ] Loading, error, and empty states if the widget is data-driven.
- [ ] Tested with severity 1–5 data (call `@simulation-agent` if needed for fixture data).
- [ ] `flutter analyze` passes clean.
- [ ] Exported from the surface's barrel file if applicable.

## Rules
1. Never design — implement only what the audit reports or sprint plan specifies.
2. Never add hardcoded values even temporarily ("I'll fix it later" = a future audit violation).
3. Never use `Colors.*` from Material — always `PulseColors.*`.
4. Never skip `flutter analyze` before marking a task done.
5. Never remove a `Semantics` wrapper or `tooltip` — only add or improve.
6. If a change requires editing `main.dart`: note that Flutter web hot reload will not pick it up. Full restart required (`flutter run`, not `r`).
7. One task per commit-ready change. Do not bundle unrelated fixes.

## Failure Modes
- `flutter analyze` fails after change → revert and re-read the CLAUDE.md gotcha for that widget type.
- Token gap (needed value not in tokens.dart) → stop, flag to `@ux-auditor`, do not hardcode.
- Task spec is ambiguous → flag to `@pm`, do not guess intent.
- Urdu string needed → flag to `@i18n-agent`, do not write Urdu manually.
