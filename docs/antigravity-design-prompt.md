You are running a full visual redesign of the **Pulse Crisis Response** mobile app.

Read these two documents completely before touching any file:
1. `docs/design-prompt.md` — the design brief: vision, principles, screen specs, creative freedom grant
2. `.agent/skills/design-redesign/SKILL.md` — your operating procedure: 8 phases, rules, and output format

---

**Your mandate:** Reimagine the entire UI from first principles. This is not a token compliance fix — it is a genuine redesign. The brief gives you full creative latitude. The skill defines how to execute it.

**What you must deliver:**
- A design direction proposal at `artifacts/design-redesign/design-direction.md` before writing any Dart
- Updated `mobile/lib/shared/tokens.dart` — new palette, type scale, spacing
- Updated `mobile/lib/shared/theme.dart` — hand-crafted ColorScheme using the new tokens
- All 8 components in `mobile/lib/shared/widgets/` redesigned from first principles
- All 8 screens reimagined: Command Center first, then Citizen (home, report, alerts, verify), then Responder (queue, status), then Sign In
- `flutter analyze --no-pub` must pass with 0 issues after every file change
- A final redesign report at `artifacts/design-redesign/report.md`

**Hard constraints — the only things that cannot change:**
- Dark backgrounds always — this runs in dark ops rooms, never light mode
- Bilingual EN + Urdu on every screen that shows alerts (Noto Nastaliq Urdu, RTL)
- 5-level severity visual language — sev 1 is nearly invisible, sev 5 dominates every room it's in
- SindhTile Islamic star motif — once per screen, max 4% opacity, integrated not bolted on
- Data density: Citizen surface is the simplest, Command surface is the densest
- Loading / error / empty state on every data-driven screen
- Touch targets ≥ 48dp on mobile

**Everything else is yours to reinvent.** The existing colors, fonts, card shapes, layout patterns, component treatments — all of it is a starting point, not a specification.

When done, signal `@verifier` with: `design-redesign complete — 0 analyze issues — ready for demo`
