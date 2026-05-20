---
name: ux-auditor
description: Reads every Dart widget and screen file, checks token usage against tokens.dart, flags hardcoded colors/sizes/radii, identifies missing states (loading/error/empty), and produces a structured violation report. Invoke before any UI sprint begins. Acts as UX Architect and UI Designer for the Tactical Humanitarian design system.
metadata:
  type: auditor
  version: 1.0.0
  tier: meta
---

# UX Auditor Skill

## Purpose
Enforce design-system integrity across the Flutter app. Every pixel must trace back to a token in `mobile/lib/shared/tokens.dart`. Every screen must have loading, error, and empty states. Every component must follow the "Tactical Humanitarian" design language defined in `CLAUDE.md`.

## Activation Triggers
- `@pm` invokes at the start of any UI/UX sprint before implementation begins.
- User says "audit the UI", "check design tokens", "find hardcoded values", "ux review".
- `@flutter-dev` requests a pre-flight check before submitting a widget change.

## Inputs
- `mobile/lib/shared/tokens.dart` — canonical token definitions (PulseColors, PulseRadii, PulseSpace).
- `mobile/lib/shared/theme.dart` — ColorScheme and TextTheme.
- `mobile/lib/shared/widgets/` — all shared widget files.
- `mobile/lib/citizen/`, `mobile/lib/responder/`, `mobile/lib/command/` — all screen files.
- `CLAUDE.md` — design language rules and gotchas.

## Procedure

### 1. Build token registry
Parse `tokens.dart` and extract:
- All `PulseColors.*` constants and their hex values.
- All `PulseRadii.*` constants.
- All `PulseSpace.*` constants.

### 2. Scan for violations
For each `.dart` file in `mobile/lib/`:

**Color violations** — flag any of:
- `Color(0x...)` or `Color.fromARGB(...)` that does not match a PulseColors value.
- `Colors.*` Material palette references (e.g. `Colors.red`, `Colors.grey`).
- Hardcoded hex strings in widget properties.

**Radius violations** — flag any:
- `BorderRadius.circular(N)` where N is not in `{0.0, 2.0, 4.0, 8.0}` (PulseRadii values).
- `RoundedRectangleBorder` with arbitrary radius.

**Spacing violations** — flag any:
- `EdgeInsets` or `SizedBox` with values not in `{4, 8, 12, 16, 20, 24, 32, 48, 64, 96}`.
- `Padding(padding: EdgeInsets.all(N))` with arbitrary N.

**Typography violations** — flag any:
- `TextStyle(fontSize: N)` defined outside `theme.dart`.
- Font family strings other than `'Fraunces'`, `'DM Sans'`, `'JetBrains Mono'`, `'Noto Nastaliq Urdu'`.

**Missing states** — for each screen file, check presence of:
- A loading skeleton or `CircularProgressIndicator` variant.
- An error state with retry affordance.
- An empty state with contextual message.

**Design language checks**:
- Map tiles must reference CartoDB dark URL (not OSM).
- `CardThemeData` must be used, not `CardTheme`.
- `StatusPill` must use a 3px leading bar, not `BorderRadius.circular` > 2.
- `SindhTile` must appear at most twice per screen.
- `CtaButton` label must start with `▸ `.

### 3. Score each file
```
violations: 0        → PASS
violations: 1-3      → WARN
violations: 4+       → FAIL
```

### 4. Produce violation report
Write `artifacts/<run-id>/ux-auditor/report.json`:
```json
{
  "agent": "ux-auditor",
  "skill_version": "1.0.0",
  "run_id": "...",
  "ts": "...",
  "summary": {
    "files_scanned": 0,
    "total_violations": 0,
    "fail": 0,
    "warn": 0,
    "pass": 0
  },
  "files": [
    {
      "path": "mobile/lib/citizen/home.dart",
      "status": "WARN | PASS | FAIL",
      "violations": [
        {
          "type": "color | radius | spacing | typography | missing_state | design_language",
          "line": 42,
          "found": "Color(0xFF123456)",
          "expected": "PulseColors.ink700 (0xFF1A2230) or nearest token",
          "severity": "error | warning"
        }
      ]
    }
  ],
  "quick_wins": ["<file>:<line> — replace X with Y"],
  "must_fix_before_sprint": ["<criterion>"]
}
```

Also write a human-readable `artifacts/<run-id>/ux-auditor/report.md` with a table per file.

## Rules
1. Never suggest a fix that introduces a hardcoded value. Always reference the token name.
2. Flag but do not auto-fix violations — hand the report to `@flutter-dev` for implementation.
3. If `tokens.dart` is missing a needed token, flag as `token_gap` and recommend addition to tokens.dart first.
4. Re-run after `@flutter-dev` closes tasks to confirm violations are resolved.
5. The "Tactical Humanitarian" dark aesthetic is non-negotiable — never recommend light-mode alternatives.

## Output to PM
After audit, emit a task list for `@pm` in this format:
```
QUICK_WIN: <file> — <1-line description> [~15 min]
MAJOR: <files> — <description> [~Nh]
TOKEN_GAP: add <token_name> to tokens.dart — needed by <files>
```

## Failure Modes
- If a Dart file cannot be parsed (syntax error), log `parse_error` and continue.
- If tokens.dart is modified mid-audit, restart scan from step 1.
- If `@flutter-dev` is unavailable, emit task list for manual implementation and pause.
