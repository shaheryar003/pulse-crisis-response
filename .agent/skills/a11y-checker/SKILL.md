---
name: a11y-checker
description: Scans Flutter widget and screen files for accessibility gaps — missing Semantics wrappers, insufficient contrast ratios on dark-slate backgrounds, and undersized touch targets. Produces a prioritized remediation list. Critical for a crisis-response app used under stress, in poor light, or by users with disabilities.
metadata:
  type: auditor
  version: 1.0.0
  tier: meta
---

# Accessibility Checker Skill

## Purpose
Ensure that every screen in the Pulse app is usable under crisis conditions: high stress, low light, one-handed operation, screen readers, and assistive technology. A crisis app that is inaccessible fails the people who need it most.

## Activation Triggers
- `@pm` invokes alongside `@ux-auditor` at the start of any UI sprint.
- User says "check accessibility", "a11y audit", "semantics check", "contrast check".
- `@flutter-dev` requests validation before submitting a widget that renders critical information.

## Inputs
- All `.dart` files in `mobile/lib/`.
- `mobile/lib/shared/tokens.dart` — color values for contrast calculation.
- WCAG 2.1 AA thresholds (built-in knowledge): 4.5:1 for normal text, 3:1 for large text (18px+ or 14px+ bold), 3:1 for UI components.

## Procedure

### 1. Semantics coverage scan
For each widget that renders meaningful content, check for a `Semantics` wrapper or equivalent:
- `Text` widgets containing incident data, severity, or status → must have `semanticsLabel` or parent `Semantics(label: ...)`.
- `IconButton` / `GestureDetector` / `InkWell` → must have `tooltip` or `Semantics(label: ...)`.
- `SeverityPill`, `StatusPill`, `IncidentCard` — check that severity/status info is exposed to screen readers.
- `Sparkbar` — chart data must be summarized in a `Semantics` node (e.g. "confidence 87%").
- `MapPin` — pin label must be readable by screen reader.
- `TraceEventCard` — tier, agent, decision, timestamp must all be in a merged `Semantics` node.
- Images and decorative icons → must be `excludeFromSemantics: true` if decorative.

Flag: `MISSING_SEMANTICS` for any meaningful widget without coverage.

### 2. Contrast ratio check
Using the PulseColors palette from `tokens.dart`, compute WCAG contrast ratios for every text+background combination found in the codebase:

| Foreground token | Background token | Expected ratio |
|---|---|---|
| pearl (0xFFE8ECF1) | ink900 (0xFF0B0F14) | ~18:1 ✓ |
| stone (0xFFB6BFCF) | ink800 (0xFF131922) | ~8:1 ✓ |
| mist (0xFF8B95A7) | ink700 (0xFF1A2230) | ~4.2:1 borderline |
| dim (0xFF5A6478) | ink700 (0xFF1A2230) | ~2.8:1 FAIL for body text |
| signal (0xFF4FD1C5) | ink900 (0xFF0B0F14) | ~9:1 ✓ |

Flag any `dim` color used for text smaller than 18px (not large text) as `CONTRAST_FAIL`.
Flag `mist` on `ink700` for body text as `CONTRAST_WARN` (borderline; recommend `stone` instead).
Flag any hardcoded color not in the token system as `UNKNOWN_CONTRAST` (cannot verify).

### 3. Touch target size check
Minimum tap target: 48×48 dp (Material / iOS HIG standard; critical for stress use).

Scan for:
- `IconButton` — Flutter default is 48dp ✓; flag if `iconSize` or `constraints` reduce this.
- `GestureDetector` / `InkWell` wrapping small widgets (< 48dp) → flag `SMALL_TARGET`.
- `CtaButton` — must be full-width or min 48dp height.
- `SeverityPill` (24×24) — is purely informational (not tappable); flag if a tap handler is added without a 48dp hit-area wrapper.
- List items in `queue.dart`, `alerts.dart` → each row must be min 48dp tall.

### 4. Text scale / overflow check
- Confirm that `Text` widgets use `overflow: TextOverflow.ellipsis` or `maxLines` where layout is constrained — critical for Urdu strings which can be longer than English equivalents.
- Confirm that no screen uses `textScaleFactor` clamping that would prevent system font-size accessibility settings from working.

### 5. Focus order check
- Confirm that tabbable elements on the Command Center dashboard follow a logical left-to-right, top-to-bottom focus order.
- Flag any `Focus` or `FocusTraversalGroup` that breaks natural reading order.

### 6. Produce report
Write `artifacts/<run-id>/a11y-checker/report.json`:
```json
{
  "agent": "a11y-checker",
  "skill_version": "1.0.0",
  "run_id": "...",
  "ts": "...",
  "summary": {
    "files_scanned": 0,
    "critical": 0,
    "warning": 0,
    "pass": 0
  },
  "findings": [
    {
      "file": "mobile/lib/command/dashboard.dart",
      "line": 88,
      "type": "MISSING_SEMANTICS | CONTRAST_FAIL | CONTRAST_WARN | SMALL_TARGET | OVERFLOW_RISK | FOCUS_ORDER",
      "severity": "critical | warning | info",
      "description": "TraceEventCard renders agent name as Text without Semantics wrapper",
      "recommendation": "Wrap with Semantics(label: '${event.agent} — ${event.decision}', child: ...)"
    }
  ]
}
```

Also write `artifacts/<run-id>/a11y-checker/report.md` — one section per file, critical findings first.

## Severity classification
| Finding type | Severity |
|---|---|
| CONTRAST_FAIL on body text | critical |
| MISSING_SEMANTICS on incident severity or status | critical |
| SMALL_TARGET on primary actions | critical |
| CONTRAST_WARN | warning |
| MISSING_SEMANTICS on decorative data | warning |
| OVERFLOW_RISK | warning |
| FOCUS_ORDER | info |

## Rules
1. `critical` findings block sprint sign-off — `@verifier` will reject without remediation.
2. `warning` findings must be logged as remediation tasks in `@pm` tracker even if not blocking.
3. Never recommend removing semantic information to "simplify" — always add coverage, never remove.
4. Contrast fixes must use existing PulseColors tokens — do not introduce new colors.
5. The dark-slate aesthetic is fixed — do not recommend a light theme as a contrast solution.

## Handoff to flutter-dev
After report, emit a prioritized task list for `@flutter-dev`:
```
CRITICAL: <file>:<line> — <fix description>
WARNING: <file>:<line> — <fix description>
```

## Failure Modes
- If a color is defined programmatically (runtime calculation), flag as `RUNTIME_COLOR — cannot verify statically`.
- If a widget's size depends on runtime data (variable-length text), note as `DYNAMIC_SIZE — verify with stress test via @simulation-agent`.
