---
name: design-redesign
description: Runs a full creative-freedom design overhaul of the Pulse mobile app. Reads the design brief in docs/design-prompt.md and reimagines every screen, token, and component — not as a Flutter token fix, but as a genuine redesign. Acts as a Senior Product Designer with complete visual latitude. Invoke when a design refresh (not just a bug fix) is wanted.
metadata:
  type: designer
  version: 1.0.0
  tier: meta
---

# Design Redesign Skill

## Purpose

Drive a full visual redesign of the Pulse app from first principles, guided by `docs/design-prompt.md`. This is **not** a token-compliance audit and **not** an incremental fix pass. It is a creative reimagining with explicit permission to override any existing design decision — color, type, layout, motion, component shape — as long as the result serves the product's mission and the three user surfaces (Citizen / Responder / Command).

The standard `@ux-auditor` / `@flutter-dev` loop enforces the *current* design system. This skill **replaces** that system.

---

## Activation Triggers

- `@design-redesign start` — full redesign pass across all 8 screens + token system
- `@design-redesign screen <name>` — redesign a single screen (e.g., `@design-redesign screen command`)
- `@design-redesign tokens` — redesign only the color/type/spacing system; screens follow in a second pass
- `@design-redesign components` — reimagine the shared widget library only
- User says "redesign the UI", "give it a new look", "push the design further", "make it more futuristic"

---

## Creative Latitude

This skill operates with explicit creative freedom. The following are **design decisions, not constraints**:

- The existing token names (`PulseColors`, `PulseRadii`, `PulseSpace`) — rename or restructure them
- The current surface palette (ink900/800/700) — keep, evolve, or replace entirely
- Inter + JetBrains Mono typography — substitute for stronger alternatives if justified
- The current component shapes (sharp pills, outlined CTAs, etc.) — redesign from scratch
- Layout structure of existing screens — rethink if it improves the use case

The following are **product constraints that cannot change**:

- Dark background (this is an ops tool for dark rooms — never light mode)
- Bilingual EN + UR (Noto Nastaliq Urdu, RTL — non-negotiable)
- Severity must remain a 5-level visual language (sev 1 = least urgent, sev 5 = catastrophic)
- Cultural groundedness (SindhTile motif, Pakistani color references)
- Data density: Citizen < Responder < Command (the hierarchy of complexity)
- All screens must have loading / error / empty states
- Touch targets ≥ 48dp on mobile

---

## Inputs

- `docs/design-prompt.md` — the full design brief (READ THIS FIRST, in full)
- `mobile/lib/shared/tokens.dart` — current token definitions (understand, then evolve)
- `mobile/lib/shared/theme.dart` — current theme (understand the structure, then replace content)
- `mobile/lib/shared/widgets/` — current component library (understand, then redesign)
- `mobile/lib/citizen/`, `mobile/lib/responder/`, `mobile/lib/command/` — current screens
- `CLAUDE.md` — product context, agent topology, functional requirements

---

## Procedure

### Phase 1 — Design Brief Immersion

Read `docs/design-prompt.md` completely. Extract:
1. The three words that define the visual direction (Tactical · Humanitarian · Intelligent)
2. The reference aesthetics (Arrival, Minority Report, NASA JPL, Palantir Gotham pre-corporate)
3. The role hierarchy (Citizen warmth → Responder clarity → Command density)
4. The semantic color intent (what teal means, what crimson means, what lime means)
5. The typographic soul (editorial header + grotesque body + monospace data + Urdu RTL)

Do not proceed until you can answer: *What does this product feel like at 3am in a crisis operations center?*

---

### Phase 2 — Design System Proposal

Before touching any Dart file, produce a design direction document at `artifacts/<run-id>/design-redesign/design-direction.md`:

```markdown
## Redesigned Design System

### Visual Concept
<1–2 sentences: the central aesthetic metaphor, e.g. "phosphorescent submarine instruments
seen through rain-spattered glass">

### Surface Palette
<6 surface colors with hex, rationale, and departure from current>

### Semantic Colors
<5 semantic colors: signal / amber / crimson / lime / saffron — with updated hex if changed>

### Glow System
<per-color glow values: rgba + blur radius — be specific>

### Typography
<per-role font choices: wordmark / heading / section labels / data / body / Urdu>
<justify any font changes from the brief suggestions>

### Geometry
<card radius / badge radius / button radius — and the design rationale>

### Motion
<3–5 key animations described in words, with duration and easing>

### Role Differentiation
<how Citizen / Responder / Command feel visually distinct>

### SindhTile Treatment
<where it appears, at what opacity, how it's integrated — not bolted on>
```

Present this to the operator for approval before implementing. If running autonomously, proceed after writing the document.

---

### Phase 3 — Token System Redesign

Rewrite `mobile/lib/shared/tokens.dart` with the new system. Rules:

1. Keep `PulseColors`, `PulseRadii`, `PulseSpace` class names — downstream code uses these
2. Replace **values** freely; renaming constants within the classes is allowed if you update all usages
3. Add new tokens if the new design requires them (e.g., glow radii, new semantic roles)
4. Remove tokens that no longer serve the design (leave no dead code)
5. Add a `PulseGlow` class if the new design uses a systematic glow vocabulary

After editing tokens.dart:
- Run `flutter analyze --no-pub` from `mobile/`
- Fix every compile error before proceeding

---

### Phase 4 — Theme Redesign

Rewrite `mobile/lib/shared/theme.dart`. Rules:
1. Replace `ColorScheme.dark(...)` values with the new palette
2. Update `TextTheme` to use the new typography choices
3. If switching fonts, update `mobile/pubspec.yaml` and `mobile/lib/main.dart`'s `GoogleFonts` or font asset declarations
4. Never use seed-color ColorScheme generation — always hand-craft the scheme

---

### Phase 5 — Component Redesign

For each widget in `mobile/lib/shared/widgets/`, rewrite to match the new system. Approach each component as a first-principles design decision:

**Do not copy-edit — redesign.**

For each component, answer before writing code:
- What is this component's job at a glance?
- What shape and treatment makes it instantly recognizable?
- How does it behave at its most critical state (sev 5, urgent, error)?

Priority order (highest visual impact first):
1. `severity_pill.dart` — the severity badge is on almost every screen
2. `status_pill.dart` — communicates state everywhere
3. `incident_card.dart` — the workhorse of Citizen and Command
4. `trace_event_card.dart` — the Command showpiece
5. `cta_button.dart` — primary action across all surfaces
6. `map_pin.dart` — visible on every map view
7. `dot_leader.dart`, `sparkbar.dart` — data density primitives
8. Remaining: `skeleton_loader.dart`, `section_label.dart`, `sindhTile.dart`

After each component rewrite:
```
flutter analyze --no-pub   # must be clean before moving to next
```

---

### Phase 6 — Screen Redesign

For each screen, implement the new design from the brief. Treat each screen spec in `docs/design-prompt.md` as the source of truth for *what* to show; treat Phase 2 design direction as the source of truth for *how* it looks.

Screen order (by visual impact and demo importance):
1. `command/dashboard.dart` — the showpiece; sets the bar
2. `citizen/home.dart` — the first thing citizens see
3. `citizen/alerts.dart` — most emotionally loaded screen
4. `citizen/report.dart` — highest-pressure UX (filed during emergency)
5. `responder/queue.dart` — most legibility-critical
6. `citizen/verify.dart`
7. `responder/status.dart`
8. `shared/auth.dart` (sign-in) — first impression

For each screen:
- Read the existing file fully before editing
- Implement loading / error / empty states (non-negotiable)
- Use only tokens from the redesigned `tokens.dart`
- Run `flutter analyze --no-pub` after each screen

---

### Phase 7 — Consistency Pass

After all screens and components are updated:

1. Run a full `flutter analyze --no-pub` — must be 0 issues
2. Check every screen has loading / error / empty state
3. Check SindhTile appears on sign-in and at most one additional screen
4. Check all Urdu text uses `Noto Nastaliq Urdu` with `TextDirection.rtl`
5. Check severity color is consistent: sev 5 is the most visually intense element on any screen it appears
6. Check the LIVE badge on Command animates (even in static design, code the animation)
7. Check trace event cards have T1–T7 accent colors, all visually distinct

---

### Phase 8 — Redesign Report

Write `artifacts/<run-id>/design-redesign/report.json`:

```json
{
  "agent": "design-redesign",
  "skill_version": "1.0.0",
  "run_id": "...",
  "ts": "...",
  "design_concept": "<1-sentence aesthetic concept>",
  "tokens_changed": {
    "colors_updated": 0,
    "colors_added": 0,
    "colors_removed": 0,
    "new_token_classes": []
  },
  "screens_redesigned": ["command/dashboard", "citizen/home", "..."],
  "components_redesigned": ["severity_pill", "incident_card", "..."],
  "analyze_issues": 0,
  "key_design_decisions": [
    "<decision 1 — what changed and why>",
    "<decision 2>",
    "<decision 3>"
  ],
  "departures_from_original": [
    "<any significant visual departure from the existing system, with rationale>"
  ],
  "ready_for_demo": true
}
```

Also write `artifacts/<run-id>/design-redesign/report.md` — a human-readable changelog with before/after descriptions for each major visual change.

---

## Design Heuristics

When making visual decisions, apply these in order:

1. **Does it serve the operator at 3am?** — If a design choice would confuse someone who is stressed, sleep-deprived, and in a noisy environment, it fails.
2. **Does it look better than before?** — Not just different. Genuinely better. If you're unsure, don't change it.
3. **Does it fit the brief?** — "Near-future crisis intelligence from 2030" — not 2015 Material, not 2010 skeuomorphism, not gratuitous neon cyberpunk.
4. **Is it semantically consistent?** — Crimson means urgent/danger in every context. Lime means confirmed/success. Never swap these.
5. **Does it earn its motion?** — Every animation must answer "what state change am I communicating?"

---

## Handoff

After the redesign report is written:
- Signal `@verifier` with: `design-redesign complete — 0 analyze issues — ready for demo`
- If `@commander` is available, trigger a scenario A dry-run to confirm the live trace renders correctly in the redesigned Command Center
- Do NOT invoke `@ux-auditor` in token-compliance mode — it enforces the *old* system. A new ux-auditor pass should be done after the new tokens.dart is the accepted source of truth.

---

## Failure Modes

- `flutter analyze` fails after token update → fix all compilation errors before any screen work (screens depend on tokens)
- Font not available in pubspec → add the `google_fonts` package or declare the font asset before using it
- SindhTile appears more than twice → remove until it appears once (sign-in) or twice max
- Urdu text loses RTL wrapping → restore `Directionality(textDirection: TextDirection.rtl, ...)` and flag to `@i18n-agent`
- Severity 5 is not the most visually intense state → strengthen the sev-5 treatment until it is
- Design feels decorative rather than functional → return to the brief: "lives depend on this software"
