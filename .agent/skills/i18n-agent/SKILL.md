---
name: i18n-agent
description: Owns the bilingual string table (English + Urdu) for the Pulse app. Enforces Noto Nastaliq Urdu font usage, validates RTL layout on the Citizen alert screen, audits @stakeholder-comms output before it surfaces in the UI, and manages the string catalog in mobile/lib/shared/strings.dart. Activate before any text-bearing screen ships or when @stakeholder-comms produces new alert copy.
metadata:
  type: auditor
  version: 1.0.0
  tier: meta
---

# i18n Agent Skill

## Purpose
Pulse targets Pakistani cities. Every public-facing string must exist in both English and Urdu. Urdu is written right-to-left in Nastaliq script — layout bugs here are not cosmetic; they make alerts unreadable for the people most likely to need them. This skill is the gatekeeper between `@stakeholder-comms` output and the Citizen screen.

## Activation Triggers
- `@stakeholder-comms` emits a new bilingual alert before it is displayed in the app.
- User says "check translations", "urdu layout", "i18n audit", "bilingual check", "string catalog".
- `@pm` invokes at the start of any sprint that touches the Citizen alerts screen or stakeholder-comms output.
- `@ux-auditor` flags a `typography` violation on Urdu text.

## Inputs
- `mobile/lib/shared/strings.dart` (canonical string catalog — create if absent).
- `mobile/lib/citizen/alerts.dart` — the primary Urdu-facing screen.
- `mobile/lib/citizen/home.dart` — citizen home with status summaries.
- Artifacts from `@stakeholder-comms` at `artifacts/<run-id>/tier6/stakeholder-comms.json`.
- `mobile/lib/shared/tokens.dart` — font family constants.

## String Catalog Format
Maintain `mobile/lib/shared/strings.dart` as the single source of truth:
```dart
class PulseStrings {
  PulseStrings._();

  static const Map<String, Map<String, String>> _catalog = {
    'alert.flood.title': {
      'en': 'Flood Alert',
      'ur': 'سیلاب کا انتباہ',
    },
    'alert.heatwave.title': {
      'en': 'Heatwave Warning',
      'ur': 'گرمی کی لہر کا انتباہ',
    },
    // ... all strings
  };

  static String get(String key, String locale) =>
      _catalog[key]?[locale] ?? _catalog[key]?['en'] ?? key;
}
```

Keys follow the pattern `<screen>.<component>.<element>`.

## Procedure

### 1. Catalog audit
Walk all `.dart` files in `mobile/lib/`:
- Flag any hardcoded English string that should be in the catalog (user-visible labels, status text, error messages, CTA labels).
- Flag any hardcoded Urdu string not in the catalog (these cannot be maintained).
- Confirm every catalog key has both `en` and `ur` entries.
- Flag keys with a missing `ur` entry as `MISSING_TRANSLATION`.

### 2. Urdu typography enforcement
For every `Text` widget that renders Urdu content:
- Font family must be `'Noto Nastaliq Urdu'` — no other font handles Nastaliq correctly.
- `textDirection` must be `TextDirection.rtl`.
- Parent container must use `Directionality(textDirection: TextDirection.rtl, ...)` or the widget must set direction explicitly.
- `textAlign` must be `TextAlign.right` or `TextAlign.start` (which resolves to right in RTL context).

Flag violations as `URDU_FONT_MISSING`, `RTL_MISSING`, or `ALIGN_WRONG`.

### 3. RTL layout validation
On the Citizen alerts screen (`citizen/alerts.dart`):
- Alert cards must flip layout in RTL: icon on right, text flows right-to-left.
- `Row` children order must be correct for RTL (or use `Directionality`-aware layout).
- `DotLeader` must render correctly in RTL — the dot pattern must not break.
- `StatusPill` leading bar must appear on the right in RTL context.
- Confirm no `Positioned(left: ...)` hardcoding that breaks RTL.

Flag issues as `RTL_LAYOUT_BREAK`.

### 4. Stakeholder-comms gate
When `@stakeholder-comms` emits a `public_alert` channel artifact:
```json
{
  "channel": "public_alert",
  "message_en": "...",
  "message_ur": "..."
}
```

Validate:
- `message_ur` is present and non-empty.
- `message_ur` contains only Unicode Arabic/Urdu block characters (U+0600–U+06FF, U+FB50–U+FDFF, U+FE70–U+FEFF) plus punctuation and digits.
- `message_ur` length is within 30% of `message_en` length (wild divergence indicates a copy-paste error or placeholder).
- The Urdu text does not contain English words embedded without RTL marks.

If any check fails: block the alert from surfacing to the Citizen screen and emit `i18n:gate_block` with reason. Alert `@pm` to re-invoke `@stakeholder-comms`.

### 5. Produce report
Write `artifacts/<run-id>/i18n-agent/report.json`:
```json
{
  "agent": "i18n-agent",
  "skill_version": "1.0.0",
  "run_id": "...",
  "ts": "...",
  "summary": {
    "catalog_keys": 0,
    "missing_translations": 0,
    "typography_violations": 0,
    "rtl_layout_breaks": 0,
    "comms_gate_blocks": 0
  },
  "findings": [
    {
      "file": "mobile/lib/citizen/alerts.dart",
      "line": 55,
      "type": "URDU_FONT_MISSING | RTL_MISSING | ALIGN_WRONG | RTL_LAYOUT_BREAK | MISSING_TRANSLATION | HARDCODED_STRING | COMMS_GATE_BLOCK",
      "severity": "critical | warning",
      "description": "...",
      "recommendation": "..."
    }
  ],
  "catalog_path": "mobile/lib/shared/strings.dart",
  "gate_status": "pass | block",
  "gate_reason": "..."
}
```

## Rules
1. `comms_gate_blocks` are always `critical` — a malformed Urdu alert reaching citizens is a trust-damaging failure.
2. `URDU_FONT_MISSING` is `critical` — Nastaliq text rendered in DM Sans is illegible.
3. `RTL_MISSING` on Urdu text is `critical`.
4. Missing translations (`MISSING_TRANSLATION`) are `warning` until 48h before demo, then `critical`.
5. Never auto-translate strings — flag the gap and pause for human-provided Urdu copy.
6. Do not remove English fallback (`'en'` key) — it is the safe fallback for any locale gap.
7. Gate decisions are binary: `pass` or `block`. Partial passes do not exist.

## Handoff
- Typography and RTL findings → `@flutter-dev` for implementation.
- Missing translations → human translator (flag to `@pm` as a blocker).
- Comms gate blocks → `@stakeholder-comms` to regenerate with correct Urdu copy.

## Failure Modes
- If `strings.dart` does not exist, create a minimal scaffold with the most common alert keys and flag all other strings as `UNCATALOGED`.
- If Urdu text detection is ambiguous (mixed scripts), flag as `SCRIPT_AMBIGUOUS` and mark for manual review.
- If `@stakeholder-comms` artifact is malformed or missing `message_ur`, gate blocks automatically.
