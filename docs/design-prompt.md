# Pulse Crisis Response — Claude Design Prompt

> **CREATIVE FREEDOM NOTE:** This prompt describes the *functional intent* and *visual direction* of the product. You are **not** constrained by the existing Flutter codebase, token names, or current implementation. Treat this as a greenfield design brief. Reinvent the color system, reshape the layout, push the typography further — as long as the result serves crisis operators at 3am in a dark room, it's on brief. Be bold.

---

## Brief

Design a complete, production-ready UI for **Pulse** — a real-time multi-agent AI crisis response platform serving emergency command centers, field responders, and citizens in Pakistani cities.

The visual identity is **"Tactical Humanitarian"**: the operational intensity of a military command interface fused with the warmth and urgency of humanitarian aid. Think **Arrival's heptapod translation room** meets **UNHCR field ops tent** — systems that feel both alien in their intelligence and deeply human in their purpose. Dark, data-dense, precise, but never cold, never militaristic. Every pixel must communicate that lives depend on this software.

Push this far beyond a standard dark dashboard. Make it feel like a **near-future crisis intelligence system from 2030** — one that's been running in production for five years by operators who know every pixel. Glass depth, ambient intelligence glow, data density that rewards experts, and micro-detail that feels discovered rather than announced.

**Reference aesthetics:** Minority Report's gesture UI stripped of gesture → mouse/touch. Arrival's circular script — organized yet organic. NOAA's weather radar terminals. Palantir Gotham before it got corporate. A beautiful NASA JPL telemetry screen. A good UNHCR situation report rendered as live software.

---

## Design Principles

### 1. Ambient Intelligence
The interface should feel alive without being distracting. Data that matters should glow softly. Critical alerts should pulse like a heartbeat — not flash like an alarm. The map should breathe. Severity 4–5 incidents radiate a subtle field of urgency that the eye gravitates toward without being told. Use soft luminescence, not neon.

### 2. Information Hierarchy Through Light
Luminance is the primary hierarchy signal — not size, not color alone. Critical information is the brightest thing on screen. Secondary data recedes. Disabled and empty elements are nearly invisible — ghosts waiting to become real. The trained eye should know where to look before it consciously decides.

### 3. Data Density Without Clutter
Every screen operates at 3× the information density of a consumer app. Dot-leader rows (label · · · · value). Monospace numeric columns. Mini sparkbar charts. Confidence percentage bars. Timestamp precision to the millisecond. Tighten everything — this is an ops tool, not a billboard. 10–12px is the default data size. White space is earned.

### 4. Micro-Motion as Communication
Animation is a language here, not decoration. A severity-5 incident's pulsing halo communicates "this is happening now." A new AI agent decision sliding in from the right says "the system just acted." Status transitions animate because state change matters. Nothing moves without a reason. Duration 200–800ms, easing easeOutQuart. Looping animations breathe at 1.5–2s cycles.

### 5. Cultural Groundedness
This software serves Pakistani operators, field responders, and citizens. An 8-point **Islamic geometric star** (SindhTile motif) appears as a subtle background texture at ≤4% opacity — once per screen, never twice. **Noto Nastaliq Urdu** renders all Urdu text with RTL respect. The palette draws from Pakistani green (teal signal), saffron, and desert amber. The product is global in precision, Pakistani in soul.

### 6. Role-Based Identity
Three surfaces, one system, three distinct characters:
- **Citizen** — Accessible, reassuring, empowering. Someone who's never used ops software before needs to file a crisis report in under 30 seconds. Warmer, more generous spacing, larger touch targets.
- **Responder** — Tactical, legible at arm's length in a moving vehicle at night. Queue-first. Every action reachable in ≤2 taps.
- **Command** — The showpiece. Maximum density. Dual-column ops + live AI trace. The kind of screen that ends up in press photos when a crisis is resolved.

### 7. Depth and Glass (Not Heavy Glassmorphism)
Surface layering creates depth without frosted-glass excess. Each layer step adds barely-perceptible depth: floor → cards → elevated panels → tooltips. Borders are thin (1px), low-opacity (8–15% white), slightly luminous. Think one step past "frosted" — think "slightly phosphorescent in the dark."

### 8. Severity as a Living Visual Language
Five severity levels, immediately distinguishable in peripheral vision:
- **Sev 1** — neutral gray, informational, nearly invisible
- **Sev 2** — teal, minor, present but calm
- **Sev 3** — amber, warning, glowing faintly
- **Sev 4** — crimson, severe, pulsing halo, demands attention
- **Sev 5** — deep crimson, catastrophic, dual-ring pulse, the thing everyone in the room is looking at

---

## Design System Direction

> These are **starting points and inspiration**, not locked specifications. Deviate where it makes the design stronger. The colors, fonts, and spacing below reflect the product's intent — interpret them freely.

### Surface Palette (Dark Blue-Grays — Never Pure Black)

The background should feel like the inside of a well-lit submarine control room, not a void. Dark blue-gray surfaces that hint at depth without swallowing content.

**Suggested starting palette:**
- Page background: near-black with blue undertone `~#0B0F14`
- Card surface: first step up `~#131922`
- Elevated panels: `~#1A2230`
- Hover / active: `~#232E3F`
- Subtle border: `~#1F2937` — barely visible, 1px
- Stronger divider: `~#2A3441`

### Text Hierarchy (Five Levels)

- Primary text: near-white with blue tint `~#E8ECF1`
- Secondary: cooler gray `~#B6BFCF`
- Tertiary / labels: muted `~#8B95A7`
- Disabled: `~#5A6478`
- Ghost / placeholder: `~#3A4252`

### Semantic Color System

These must remain semantically consistent — do not swap what red means vs. what green means. The visual expression is yours.
- **Signal / primary action / "safe"** — Teal `~#4FD1C5` — also the Pakistani flag green translation
- **Caution / warning** — Amber `~#F5A524`
- **Urgent / critical / error** — Crimson `~#F31260`
- **Confirmed / success / acknowledged** — Lime `~#B5E853`
- **Cultural accent / infrastructure** — Saffron `~#E0A458`

**Glow suggestions** (for box-shadow / drop-shadow on critical elements):
- Teal glow: `rgba(79,209,197,0.25)` blur 12px
- Crimson glow: `rgba(243,18,96,0.30)` blur 16–24px
- Amber glow: `rgba(245,165,36,0.25)` blur 12px
- Lime glow: `rgba(181,232,83,0.20)` blur 12px

### Typography Direction

The product needs two souls: editorial authority for the wordmark/titles, and terminal precision for data.

**Suggested type roles:**
| Role | Suggested Font | Notes |
|---|---|---|
| PULSE wordmark | Fraunces (italic serif) or equivalent editorial serif | Conveys weight and authority |
| Page titles & headings | Inter Bold 700 or any strong grotesque | Clean, trustworthy |
| Section labels (ALL CAPS) | Inter Semi Bold 600, letter-spacing +1.4px | 10–11px, mist color |
| Data / metrics / IDs | JetBrains Mono or similar monospace | 10–16px, tabular numbers |
| Alert body copy | Inter Regular 400 | 13–14px |
| Urdu text | Noto Nastaliq Urdu | 14–15px, RTL, line-height 1.6 |

> Feel free to substitute or upgrade fonts — the direction is: editorial header + grotesque body + monospace data + Urdu RTL.

### Spacing & Geometry

Base-4 or base-8 spacing system. Cards: rounded corners ~12px. Badges and status pills: deliberately sharp, ~2px radius — these are data objects, not decorative bubbles. Buttons: ~12px radius. The geometry should feel precise, not rounded-off.

---

## Screen Specifications

The following defines the **functional content and states** of each screen. Layout, visual treatment, and component design are yours to interpret. Serve the use case — own the aesthetic.

---

### SCREEN 1 — Sign In / Access Gate

**The moment a new user or shift commander unlocks the system.** It should feel like gaining clearance, not filling a form.

**Functional content:**
- PULSE wordmark (prominent, top-center) + version badge
- Subtitle: `Urban Crisis Response · Islamabad operations`
- **Step 1:** API endpoint field + phone number field + "Request OTP" action
- **Step 2** (revealed after request): OTP code field + role selector (CITIZEN / RESPONDER / COMMAND) + "Verify & Continue" action
- Role selector must make each role feel distinct — not just three equal tabs
- Demo hint: `Demo OTP: 654321`
- Privacy footnote: phone is hashed before processing

**Design direction:** The SindhTile motif should appear here, most prominently on this screen. The sign-in card should feel like a briefing document materializing from the dark background.

---

### SCREEN 2 — Citizen: Live Incident Map

**The citizen's situational overview. The map is the hero.**

**Functional content:**
- Role-aware top bar: PULSE wordmark + CITIZEN badge + 4 tabs (MAP / REPORT / ALERTS / VERIFY)
- **Dark basemap** (CartoDB dark_all or equivalent dark tile) centered on Islamabad, zoom ~12
- Incident markers on map: each showing severity visually (color, size, pulse for high severity)
- Below map: section header `ACTIVE INCIDENTS · COUNT {N}`
- Loading state: shimmer skeleton cards
- Empty state: graceful "no incidents" message
- Per incident card:
  - Severity indicator + incident type + zone name
  - Key data: confidence, population affected, spread risk
  - Forecast bands (P10/P50/P90) if available
  - Status + time ago
- Pull-to-refresh gesture

**Design direction:** The map should feel like looking at a live intelligence feed — not a tourist map. Dark tiles with glowing incident markers. High-severity incidents should visually dominate the map without explanation.

---

### SCREEN 3 — Citizen: Report an Incident

**A frightened civilian using this at 2am during a flood. Fast, reassuring, clear.**

**Functional content:**
- Header: `Report an incident` + supporting subtext
- **Category selection** (7 options): FLOOD · FIRE · ACCIDENT · POWER OUTAGE · WATER MAIN · INFRASTRUCTURE · OTHER
  - Each category has an icon + label
  - Selected state visually distinct and obvious
- **Description field:** multi-line text, 3–6 rows
- **Evidence capture (2 actions side by side):**
  - Capture GPS location (shows coordinates + accuracy when captured)
  - Attach photo (shows confirmation when attached)
- **Submit** action (primary CTA, full-width)
- Success state: confirmation with submission reference
- Error state: informative, with offline-queue explanation if network unavailable
- Privacy footnotes (unobtrusive): phone hashed, trust scoring

**Design direction:** This screen should feel the most accessible of the three surfaces. Generous touch targets, clear feedback, confidence that the report was received. The category chips can be more expressive — icons should be immediately recognizable under stress.

---

### SCREEN 4 — Citizen: Alerts Feed

**Official communications from the command system to citizens.**

**Functional content:**
- Header: `Alerts` + summary count (issued / retracted)
- Loading: shimmer skeletons
- Empty: friendly placeholder
- **Active alert card:**
  - Visual priority indicator (related to incident type — flood=water/blue/crimson, fire=amber, etc.)
  - `PUBLIC ALERT` label + timestamp + alert ID
  - English alert body text
  - Urdu alert text (RTL, below English, Noto Nastaliq)
  - Status footer: ACTIVE pill + emergency contact info
  - Pending human approval: pulsing amber indicator + "PENDING APPROVAL"
- **Retracted alert card:**
  - Visually de-emphasized (but not hidden — transparency is the principle)
  - Original text struck through
  - `CORRECTION` section with EN + UR retraction text
  - `RETRACTED` status pill + retraction timestamp

**Design direction:** Active alerts should feel urgent and authoritative — this is the official voice of the crisis response system. Retracted alerts must be clearly corrective without being embarrassing — show the correction prominently, not a "deleted" state.

---

### SCREEN 5 — Citizen: Verify Nearby Incidents

**Citizen scientists helping validate AI classifications.**

**Functional content:**
- Header: `Verify nearby` + description of purpose
- Per incident:
  - Severity + type + zone identification
  - Two actions: `▸ CONFIRM` and `▸ DISPUTE`
  - Loading state for submission
  - Post-submission state: CONFIRMED (with lime accent) or DISPUTED (with amber accent) + confirmation text

**Design direction:** Should feel like meaningful contribution — "your verification improves the system's accuracy" — not checkbox crowdsourcing. The post-submission state should acknowledge the contribution.

---

### SCREEN 6 — Responder: Dispatch Queue

**A rescue team leader checking assignments on a phone while running to their vehicle.**

**Functional content:**
- Header: `Dispatch queue` + asset ID + active count
- Asset selector (load by ID)
- **Per dispatch card:**
  - Priority level badge: URGENT (crimson) / HIGH (amber) / STANDARD (teal)
  - Severity indicator + incident reference
  - Key data: destination zone, ETA, current status
  - Instructions block (full text)
  - Status action buttons: ACK → EN ROUTE → ON SCENE → CLEAR
    - Each button reflects current state
    - Active/completed state visually distinct (lime for done)

**Design direction:** Maximum legibility. Touch targets ≥48dp. URGENT should be impossible to miss. The status workflow (ACK → EN ROUTE → ON SCENE → CLEAR) should feel like a physical process being tracked, not a form being filled.

---

### SCREEN 7 — Responder: Status Update

**30-second check-in to keep command informed of unit availability.**

**Functional content:**
- Header: `Report status` + unit description
- Asset ID field
- Availability selector: ON DUTY (lime) / STANDBY (amber) / OFF DUTY (dim)
- Submit action
- Success/error feedback
- Logged-as footer

**Design direction:** Dead simple. Every interaction should be completable with one thumb. The availability selector should be the focal point of the screen.

---

### SCREEN 8 — Command Center Dashboard

**The showpiece. A shift commander managing a city-wide flood response sees this screen for 12 hours straight.**

**Functional content:**
- Top bar: PULSE wordmark + scenario runner dropdown + controls
- **Degraded mode banner** (stacks when active): per data-source degradation warning
- **Left column (60%):** Operations view
  - Live header with LIVE indicator + timestamp
  - Tactical dark basemap with all active incidents
  - Incident list (selectable, loads detail panel)
  - **Incident detail panel** (on select):
    - Confidence + spread risk metrics
    - **Audit chain** (read-only, append-only log):
      - Tier-7 AI agent review entries
      - Incident type flips (original → revised)
      - Severity before/after
      - Alert retraction details + recipient counts
      - Responsible agent chain
  - **Resource gauges:** 9 asset types with count + utilization bar (ambulance, rescue, fire, police, water, mobile clinic, utility crew, generator, drone)
- **Right column (40%):** Live AI Agent Trace
  - WebSocket connection badge (LIVE / DISCONNECTED)
  - Real-time stream of AI agent decisions, newest at top
  - **Per trace event card:**
    - Tier badge (T1–T7) with tier-specific accent color
    - Agent name + millisecond timestamp
    - Decision text + confidence score
    - Expandable detail block (hypothesis + key-value evidence rows)
    - New events slide in with brief accent border flash

**Tier accent colors (must be visually distinct T1–T7):**
- T1 Ingest: neutral/stone
- T2 Fusion: amber
- T3 Classify: teal/signal
- T4 Forecast: saffron
- T5 Coordinate: crimson
- T6 Act: lime
- T7 Recover: mist/cool gray

**Mobile layout (< 1100px):** OPS tab / TRACE tab switcher — each pane takes full screen.

**Design direction:** This is the screen that should appear on a conference stage and make the audience lean forward. The right pane should look like a live feed of AI agents making decisions in real time — because that's exactly what it is. The audit chain should feel like a transparent, trustworthy system that could hold up in court.

---

## Component Design Direction

These components appear across all screens. Each one should be reimagined from first principles — not copied from an existing UI kit. They need to work together as a cohesive system.

**SeverityPill** — The severity level badge. Square (not circular), 24×24px nominal. Sharp corners. Five visually distinct states. Severity 4+ must pulse. Severity 5 must dominate any screen it appears on.

**StatusPill** — State communication. Not rounded-full — this is data, not decoration. A left-side color bar or other strong indicator. ALL CAPS label. Should read at a glance from 1m away.

**CTA Button** — Primary action. Arrow-prefixed label (`▸ LABEL`). Outlined treatment with colored text and subtle fill. Loading state. Full-width in single-column layouts.

**DotLeader** — `label · · · · · · value`. The workhorse of data display. Should feel like a technical document, not a form.

**Sparkbar** — 10-cell mini utilization chart. Appears in resource gauges and incident cards.

**TraceEventCard** — The Command Center right-pane card. Tier badge + agent name + timestamp + decision + expandable detail. Seven tiers with seven visually distinct accent colors. This component tells the story of an AI system thinking in real time.

**ApprovalGateBadge** — Pulsing amber indicator for alerts awaiting human review before dispatch.

**SkeletonLoader** — Shimmer loading placeholder. Used everywhere before data arrives.

---

## Animation Philosophy

Motion communicates state change. Never decorative. If removing an animation doesn't hurt comprehension, remove it.

Key animations to nail:
- New AI trace event entering the feed (slide in from right, brief border flash, then settles)
- Severity 4+ incident halo (soft, steady pulse — like a breathing hazard indicator)
- WebSocket LIVE badge (barely-perceptible glow breathe)
- Skeleton → content transition (fade/dissolve, not pop)
- Incident selection (instant left-border accent appear, card border glow)

---

## Responsive Layout

**Mobile (≤ 768px):** Single column. Command Center uses OPS/TRACE tab switcher.

**Tablet (769–1099px):** Single column, generous padding.

**Desktop / Web (≥ 1100px):**
- Command: 60/40 two-column, full viewport height, right pane independently scrollable
- Citizen/Responder: centered, max-width ~720px
- Sign in: centered card, max-width ~460px

---

## Copy & Content Tone

The product speaks with authority and precision. No marketing language. No softening.
- Section headers: ALL CAPS, tracked out, muted color — `ACTIVE INCIDENTS · COUNT 3`
- Em-dash leaders: `— Your report routes to Pulse command in real time` (em-dash, not hyphen)
- Status words: ALL CAPS — CONFIRMED · DISPUTED · RETRACTED · ACCEPTED · LIVE · DISCONNECTED
- Data labels: lowercase monospace — `zone` · `eta` · `confidence` · `spread risk`
- Timestamps: `HH:MM:SS` minimum, `HH:MM:SS.mmm` for agent trace events

---

## Deliverable List

Design all of the following in both **mobile (390×844)** and **desktop (1440×900)** frames:

1. **Sign In** — Step 1 (fields) + Step 2 (OTP + role selector shown)
2. **Citizen: Map** — 3 active incidents (sev 2/3/5) on dark map + incident list
3. **Citizen: Report** — FLOOD category selected + GPS captured + description filled
4. **Citizen: Alerts** — 1 active EN+UR alert (pending approval) + 1 active flood crimson alert + 1 retracted alert with correction
5. **Citizen: Verify** — 3 incidents (1 idle, 1 confirmed, 1 disputed)
6. **Responder: Queue** — 2 dispatches (1 URGENT/en_route, 1 HIGH/issued)
7. **Responder: Status** — STANDBY selected + success state
8. **Command Center** — live map + 2 incidents + selected incident with audit chain visible + 8 trace events (T1–T7 represented) + DEGRADED banner active

Additionally:

9. **Component sheet** — SeverityPill (all 5), StatusPill (all color variants), CtaButton (default/loading/disabled), DotLeader, Sparkbar, TraceEventCard (all 7 tiers), ApprovalGateBadge, SkeletonLoader
10. **Design system sheet** — Full color palette with swatches + glow values, typography scale, spacing scale, radii scale, SindhTile motif sample
