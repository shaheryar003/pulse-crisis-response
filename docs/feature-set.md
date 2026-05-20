# Pulse — Complete Feature Set for UI Design

> **System:** Multi-agent urban crisis response platform for Pakistani cities (Islamabad).  
> **Design language:** "Tactical Humanitarian" — dark slate operations dashboard with editorial typography and humanitarian warmth.  
> **Surfaces:** Web app + mobile app (Flutter). Identical feature set; web uses wider two-column layouts.

---

## 1. Design Tokens

### Color Palette

| Token | Hex | Role |
|---|---|---|
| `ink900` | `#0B0F14` | Page background |
| `ink800` | `#131922` | Card / surface background |
| `ink700` | `#1A2230` | Elevated surface |
| `ink600` | `#232E3F` | Subtle hover state |
| `hairline` | `#1F2937` | Default border |
| `hairlineStrong` | `#2A3441` | Divider / separator |
| `pearl` | `#E8ECF1` | Primary text |
| `stone` | `#B6BFCF` | Secondary text |
| `mist` | `#8B95A7` | Tertiary / placeholder |
| `dim` | `#5A6478` | Disabled / subtle |
| `signal` | `#4FD1C5` | Primary action / info (teal) |
| `amber` | `#F5A524` | Caution / pending / warning |
| `crimson` | `#F31260` | Urgent / critical / error |
| `lime` | `#B5E853` | Success / acknowledged / confirmed |
| `saffron` | `#E0A458` | Cultural accent (Pakistan saffron) |
| `sev1` | `#5A6478` | Severity 1 — INFO |
| `sev2` | `#4FD1C5` | Severity 2 — MINOR |
| `sev3` | `#F5A524` | Severity 3 — MAJOR |
| `sev4` | `#F31260` | Severity 4 — SEVERE |
| `sev5` | `#B30038` | Severity 5 — CATASTROPHIC |

**Rule:** Dark mode only. No light mode. No pure black backgrounds.

### Typography

| Style | Font | Weight | Size | Usage |
|---|---|---|---|---|
| Display | Fraunces (serif, italic) | 700 | 22–48px | Page titles, PULSE wordmark |
| Label | DM Sans | 600 | 10–12px | ALL-CAPS section labels, pill text, tab labels |
| Data | JetBrains Mono | 400–700 | 10–16px | Coordinates, IDs, timestamps, metrics |
| Data SM | JetBrains Mono | 400 | 11–12px | Sub-metrics, fine print |
| Data XS | JetBrains Mono | 400 | 10px | Short IDs, epoch timestamps |
| Urdu body | Noto Nastaliq Urdu | 400 | 14–15px | Urdu alert text (RTL) |

### Spacing Scale

`x1=4 · x2=8 · x3=12 · x4=16 · x5=20 · x6=24 · x8=32 · x12=48 · x16=64`

### Border Radius Scale

`sharp=0 · xs=1 · sm=2 · md=4 · lg=8 · xl=12 · xxl=16`

### Cultural Motif

`SindhTile` — subtle 8-point Islamic geometric star, used at max 4% opacity, max once per screen, bottom-anchored. Adds Pakistani cultural identity without visual noise.

---

## 2. Global Shell Components

### Top Utility Bar (`UtilBar`)
- Fixed, full-width, `ink900` background with `hairline` bottom border
- **Left:** `PULSE` wordmark (Fraunces italic, 20px) + role indicator pill (• CITIZEN / • RESPONDER / COMMAND)
- **Center:** Horizontal tab list — underline-style active indicator in `signal` teal, 48dp min-height touch targets, ALL-CAPS labels
- **Right:** Icon buttons (logout, refresh) — 32×32 icon in 40×40 touch area

### Auth Gate (loading splash)
- `ink900` background, centered `CircularProgressIndicator` in `signal` color, 24×24, strokeWidth 1.5
- Shown while session token is restored from storage

---

## 3. Authentication — Sign In (`SignInPage`)

**Layout:** Centered card, max-width 460px, full-height `ink900` background.  
**Background decoration:** `SindhTile` at 3% opacity, anchored to bottom, height 240px.

### Sections

#### Hero
- `PULSE` wordmark — Fraunces italic, 48px, `pearl`
- `v0.1` version badge — JetBrains Mono XS, `dim`, baseline-aligned
- Subtitle line: `— Urban Crisis Response · Islamabad operations` (em-dash leader style)

#### Step 1 — Phone Entry
- **API Endpoint field** — labeled `API ENDPOINT`, monospace input, placeholder `http://localhost:8000`
- **Phone field** — labeled `PHONE`, phone keyboard, monospace input, placeholder `03149946492`
- **▸ REQUEST OTP** CTA button (teal outlined, full-width)

#### Step 2 — OTP Entry (shown after OTP sent)
- **One-Time Code field** — labeled `ONE-TIME CODE`, numeric keyboard, placeholder `654321`
- **Role selector** — segmented 3-option toggle: `CITIZEN · RESPONDER · COMMAND`
  - Active: `signal` bottom underline + 5×5 dot indicator + teal tint background
  - Inactive: `mist` text
- **▸ VERIFY & CONTINUE** CTA button

#### Footer
- `— Demo OTP is 654321 · phone is hashed before processing`
- `— Antigravity build a215.7 · 2026-05-15`

#### Error state
- Crimson-bordered container, 6% crimson background fill, error message in `dataSm` style

---

## 4. Citizen Surface (4 tabs: Map · Report · Alerts · Verify)

### Tab 4.1 — Map (Live Incidents)

**Header section**
- Display title: `Live incidents`
- Subtitle em-dash leader: `{N} active · last update HH:MM:SS`

**Interactive map**
- CartoDB dark tile layer (NOT OpenStreetMap)
- Aspect ratio 16:11, rounded border `xl`, `hairline` border
- Centered on Islamabad: lat 33.700, lon 73.040, zoom 12
- **MapPin markers** per active incident:
  - Circular badge with severity numeral (1–5)
  - Color matches severity scale (dim → signal → amber → crimson → sev5)
  - Pulsing halo animation for severity 4+ incidents (draws attention)
  - Aria label: `Severity X Y incident in ZONE`

**Active incidents list**
- Section label: `Active incidents · count {N}`
- **Loading state:** 3× skeleton loaders (height 100, rounded `xl`)
- **Error state:** Crimson error box with `NETWORK ERROR` label + `RETRY` button
- **Empty state:** Em-dash leader: `— No active incidents in your area.`
- **Populated:** `IncidentCard` list (see Component Library §8)

---

### Tab 4.2 — Report an Incident (`CitizenReportPage`)

**Header**
- Display title: `Report an incident`
- Subtitle: `— Your report routes to Pulse command in real time`

**Category section** — label: `CATEGORY`
- 7-option chip grid (Wrap layout): FLOOD · FIRE · ACCIDENT · POWER OUTAGE · WATER MAIN · INFRASTRUCTURE · OTHER
- Each chip: icon (28px) + ALL-CAPS label (10px), min 96×80dp
- **Selected:** teal 1.5px border + 15% teal background + teal glow shadow + teal icon/text
- **Unselected:** `hairline` border + `ink800` 50% background + `stone` icon/text

**Description section** — label: `DESCRIPTION`
- Multi-line text field, 3–6 lines, `pearl` text, placeholder: `What is happening?`

**Evidence section** — label: `EVIDENCE`
- Two side-by-side evidence cards (Row):
  - **CAPTURE GPS card:** `◎` marker, lime border when captured, shows `lat, lon \n ±Xm` on success with `✓` checkmark
  - **ATTACH PHOTO card:** `⊕` marker, lime border when attached, shows `photo attached` on success
  - Both cards: `hairline` border default, glow shadow on capture, `tap to capture` prompt text

**Submit**
- `▸ SUBMIT REPORT` CTA button (full-width, teal)
- **Loading:** spinner replaces arrow

**Success state**
- Lime-bordered container: `ACCEPTED` status pill + `Submitted · zone {ZONE} · credibility {X.XXX}` in lime mono

**Error / offline state**
- Crimson-bordered container with error message
- Reports offline-queued via `SharedPreferences` when API unreachable

**Privacy footer**
- `— Your phone number is hashed before processing`
- `— False reports degrade your trust score`

---

### Tab 4.3 — Alerts (`CitizenAlertsPage`)

**Header**
- Display title: `Alerts`
- Counter: `{N} issued · {N} retracted`

**Loading state**
- 3× skeleton loaders (height 120, rounded `xl`)

**Empty state**
- `— No alerts yet — run a scenario from Command.`

**Alert cards** (`_AlertCard`) — left-accent strip design:
- **Structure:** thin 3dp colored left strip + `ClipRRect` rounded `xl` outer border
- Accent color derived from `incidentType` field:
  - `flood / water_main_burst / fire` → crimson
  - `heat / heatwave / power_outage` → amber
  - `accident / infrastructure` → saffron
  - `default` → signal (teal)
  - Retracted → dim (gray)

**Card header row**
- Icon: `⚠` (active) or `⊘` (retracted) in accent color
- Label: `PUBLIC ALERT` or `RETRACTED` in accent color, ALL-CAPS
- Right: timestamp `HH:MM:SS` + short alert ID (`Alert #XXXX`)

**Card body**
- English alert text — `pearl`, 13px, strikethrough + `dim` color if retracted
- Urdu alert text — Noto Nastaliq Urdu, 15px, RTL, `stone`, below English; strikethrough if retracted

**Retraction block** (shown only when retracted)
- `CORRECTION ————` divider row
- English correction text: `The original alert has been retracted.`
- Urdu correction text (RTL): `پہلی اطلاع واپس لی جا چکی ہے۔ متعلقہ ادارے کام کر رہے ہیں۔`

**Card footer row**
- `ACTIVE` status pill (accent color) or `RETRACTED` pill (dim)
- Retracted alerts: `retracted HH:MM:SS`
- Active with human approval pending: `ApprovalGateBadge` (pulsing amber dot + `⏳ PENDING APPROVAL`)
- Active alerts: helpline number `— Call 1122 for emergencies`

---

### Tab 4.4 — Verify Nearby (`CitizenVerifyPage`)

**Header**
- Display title: `Verify nearby`
- Subtitle: `— Confirm or dispute incidents near you to improve accuracy`

**Loading state:** Spinner (22×22, signal, strokeWidth 1.5)

**Empty state:** `— No incidents nearby to verify.`

**Verify cards** (`_VerifyCard`) — per active incident:
- Row header: `SeverityPill` (square badge) + incident type ALL-CAPS + zone name
- **Idle state:** divider + two full-width buttons:
  - **▸ CONFIRM** — lime CTA (user is physically seeing the incident)
  - **▸ DISPUTE** — amber CTA (user cannot confirm the classification)
- **Busy state:** both buttons show loading spinner
- **Confirmed:** `CONFIRMED` status pill (lime) + `— Verification submitted.`
- **Disputed:** `DISPUTED` status pill (amber) + `— Verification submitted.`

**Pull-to-refresh** supported (signal-colored refresh indicator)

---

## 5. Responder Surface (2 tabs: Queue · Status)

### Tab 5.1 — Dispatch Queue (`ResponderQueuePage`)

**Header**
- Display title: `Dispatch queue`
- Counter: `asset {ASSET_ID} · {N} active`

**Asset selector row**
- Text field (monospace, default `rescue-3`) + `LOAD` outlined button
- Submitting asset ID refreshes the dispatch list

**Loading / Error / Empty states** — same pattern as citizen (spinner / ErrorBox / em-dash leader)

**Dispatch cards** (`_DispatchCard`) — per assigned dispatch:

*Top row*
- `StatusPill.priority()` — `URGENT` (crimson) / `HIGH` (amber) / standard (signal)
- Right: short dispatch ID in `dataXs`

*Incident row*
- `SeverityPill` (pulsing if urgent) + `INCIDENT · {short ID}` label

*Data rows* (dot-leader layout)
- `DESTINATION ·····················  {zone label}` (if destination set)
- `ETA ·································  {N}m`
- `STATUS ······························ {status}` (colored by priority)

*Instructions block*
- `INSTRUCTIONS` label + full instructions text (`pearl`, 13px)

*Action buttons* (Wrap layout, 48dp min-height each):
- `ACK` — primary (signal) when status=issued; active (lime+checkmark) when acked
- `EN ROUTE` — active when status=en_route
- `ON SCENE` — active when status=on_scene
- `CLEAR` — active when status=clear
- Disabled buttons: `hairline` border, `dim` text

**Pull-to-refresh** supported

---

### Tab 5.2 — Status Reporting (`ResponderStatusPage`)

**Header**
- Display title: `Report status`
- Subtitle: `— Update your unit availability for command`

**Asset ID field**
- Monospace text input, default `rescue-3`, label: `ASSET ID`

**Availability selector** — 3-option segmented control (on_duty / standby / off_duty):
- Same segmented toggle pattern as role selector
- `on_duty` → lime accent
- `standby` → amber accent
- `off_duty` → dim accent
- Active option: colored bottom border + 5×5 dot indicator + color-tinted background
- Min-height 48dp each option

**▸ UPDATE STATUS** CTA button

**Success state**
- Lime-bordered container: `UPDATED` status pill + `Status updated: {status}` message

**Error state**
- Crimson-bordered container with error text

**Footer**
- `— Logged as {userId} · {assetId}`

---

## 6. Command Center Surface (single full-screen view)

**Header bar** — `UtilBar` with:
- `▸ RUN ▾` scenario menu (teal bordered, dropdown): Scenario A · B · C · D
- Refresh icon button
- Sign out icon button

**Degraded-mode banner** (conditional, stacked above main content)
- Per degraded signal: amber 3dp left border + `DEGRADED` status pill + detail text + `×` dismiss button
- Types: weather cache stale (shows `stale: {N} min`) / sensor silent (shows sensor ID)

### Layout: Wide (≥ 1100px) — two-column
- Left pane (60%): Operations view
- Right pane (40%): Live trace feed
- Vertical divider: 1px `hairline`

### Layout: Narrow — tabbed
- `OPS` tab / `TRACE` tab
- Tab bar: `signal` indicator underline, ALL-CAPS 11px labels

---

### Left Pane — Operations

**Section: Dashboard header**
- Display title: `Command · Ops Center`
- Live indicator: 6×6 lime dot with 0.4 opacity glow + `LIVE` label
- Counter: `{N} active · HH:MM:SS`
- `ErrorBox` if incident fetch fails (with retry)

**Section: Tactical map (16:9)**
- CartoDB dark tiles, zoom 12, Islamabad center
- `MapPin` per incident: severity numeral, pulsing halo for sev 4+, zone tooltip label

**Section: Active incidents list**
- `SectionLabel` with count
- `IncidentCard` per incident — tappable, selected state (teal left border highlight)
- Tapping loads incident detail below

**Section: Incident detail panel** (appears on tap)
- `SectionLabel`: `Incident detail · {short ID}`
- Skeleton loader while fetching
- Confidence dot-leader row
- Spread risk dot-leader row (HIGH=crimson / MEDIUM=amber / other=mist)
- `AuditChainPanel` — Tier-7 audit chain (see §8 Component Library)

**Section: Resource gauges**
- Container with `hairline` border + `ink800` 50% background
- Per asset type: label (110px fixed) + count (mono, right-padded) + `Sparkbar` fill indicator
- Asset types: ambulance · rescue · fire_unit · police_traffic · water_tanker · mobile_clinic · utility_crew · generator · drone

---

### Right Pane — Live Trace Feed

**Trace header**
- `LIVE` badge (teal border) or `DISCONNECTED` badge (amber border) — WebSocket connection status
- Title: `Agent trace`
- Event count: `{N} events` in `dataXs`

**Empty state:** `— Waiting for pipeline events. Run a scenario or submit a report.`

**Trace event cards** (`TraceEventCard`) — scrolling list, newest on top:
- Tier badge: T1–T7, each with distinct color:
  - T1 Ingest → stone (gray)
  - T2 Fusion → amber
  - T3 Classify → signal (teal)
  - T4 Forecast → saffron
  - T5 Coordinate → crimson
  - T6 Act → lime
  - T7 Recover → mist
- Agent name + decision label
- Confidence percentage bar (if present)
- Hypothesis label (if present)
- Timestamp: `HH:MM:SS.mmm` (millisecond precision)
- Detail rows (collapsible, shown for newest event):
  - T1: zone, trigger, stale_minutes
  - T2: candidate_id, diversity_score, avg_credibility
  - T3: type, severity, low_confidence
  - T4: spread_risk
  - T5: incident_id, trade_offs, resource_shortfall
  - T6: channel, body_en, requires_human_approval
  - T7: retraction_message_en
- `NEW` flash badge on most-recent event (lime, fades)

---

## 7. Data Models (for design state)

### Incident
```
id          string        — inc_xxxxxxxxxx
zone        string        — G-10, F-7, I-9…
type        string        — flood / fire / heatwave / accident / power_outage / water_main_burst / infrastructure_failure
severity    int 1–5       — 1=INFO → 5=CATASTROPHIC
status      string        — active / retracted
confidence  float 0–1
spread_risk string        — low / medium / high
popP10/P50/P90  int?      — Tier-4 Monte Carlo population bands
radiusKmP10/P90 float?    — uncertainty radius bands
```

### Alert
```
alertId           string
incidentId        string
channel           string  — public_push
bodyEn            string? — English alert text
bodyUr            string? — Urdu alert text (RTL)
issuedAt          string  — ISO timestamp
isRetracted       bool
retractedAt       string?
requiresHumanApproval bool
incidentType      string? — flood / fire / heatwave…
```

### Dispatch
```
id                string
incidentId        string
assetId           string
priority          string  — urgent / high / standard
status            string  — issued / acked / en_route / on_scene / clear
etaS              int?    — ETA in seconds
instructions      string
incidentSeverity  int?
destinationZone   string?
destinationLabel  string?
```

---

## 8. Component Library

### `SeverityPill`
- 24×24 square badge (sharp corners, NOT rounded)
- Numeral centered in JetBrains Mono bold, 12px
- Border 1px in severity color
- Background: severity color at 12% opacity
- Pulsing halo animation for severity 4+
- Semantics label: `Severity X — LABEL`

### `StatusPill`
- 3dp left colored bar + ALL-CAPS label (10px DM Sans 600)
- NOT rounded-full — rectangular pill with sm (2px) radius
- Dense variant: smaller padding

### `IncidentCard`
- `ink800` background + `hairline` border + `xl` radius
- **Header row:** SeverityPill + type ALL-CAPS (12px) + zone (stone, small)
- **Data rows:** dot-leader layout (`DotLeader`)
  - Zone · confidence sparkbar · population p50
  - If `hasBands`: `ForecastBands` widget (P10/P50/P90 bars)
  - If `spreadRisk`: colored dot + risk label
- **Footer:** status pill + time since reported
- Selected state (command): teal 2px left border accent

### `DotLeader`
- `label · · · · · · · · · · · · · value` layout
- Dots via `CustomPaint` (not actual dots characters)
- Label: `mist`, 10px mono · Value: configurable color, 12px mono

### `Sparkbar`
- 10-cell mini bar chart (horizontal)
- Filled cells: configurable color (default `signal`)
- Empty cells: `hairline` color

### `ForecastBands`
- Three rows: P10 (mist) / P50 (signal) / P90 (amber)
- Proportional fill bar via Expanded flex
- Labels: `P10 ·` `P50 ·` `P90 ·` in data style

### `TraceEventCard`
- Tier colored left accent (see tier color map above)
- Agent name + decision + hypothesis chips
- Millisecond timestamp + confidence bar
- Expandable detail rows

### `AuditChainPanel`
- Read-only Tier-7 audit log (ZERO edit/delete affordances)
- Each entry: `T7` badge + `original type → revised type` flip
- Severity before/after
- Retraction message
- Recipients count + responders recalled count
- Evidence chain as em-dash leader rows
- Responsible agent chain

### `DegradedModeBanner`
- Stacked rows, one per degraded signal
- Each row: 3dp amber left border + `DEGRADED` status pill + detail text + `×` dismiss
- Shown above all content, below top bar

### `ApprovalGateBadge`
- Pulsing amber dot (2s animation) + `⏳ PENDING APPROVAL` label
- Shown on alerts where `requiresHumanApproval = true`

### `ErrorBox`
- Crimson 1px border + 6% crimson background fill + `xl` radius
- `NETWORK ERROR` label (crimson, ALL-CAPS)
- Error detail text (crimson, dataSm)
- `RETRY` outlined button

### `SkeletonLoader`
- Animated shimmer placeholder
- Configurable height and border radius
- `hairline` base + lighter shimmer sweep

### `CtaButton`
- Full-width outlined button: `▸ LABEL` format
- `signal` teal border + text
- 6% teal background fill when active
- Loading state: `CircularProgressIndicator` replaces arrow

### `SindhTile`
- 8-point Islamic star geometric pattern
- Pure CustomPainter, no image asset required
- Max opacity 4%, max once per screen, bottom-anchored

---

## 9. Interaction Patterns

| Pattern | Detail |
|---|---|
| Pull-to-refresh | All list screens; `signal` indicator, `ink800` background |
| WebSocket live updates | Command trace pane; auto-reconnect 3s → 10s exponential; LIVE/DISCONNECTED badge |
| Offline report queue | Citizen report queued to `SharedPreferences` when API unreachable |
| Skeleton loading | 3 placeholder cards before real data arrives |
| Role-gated navigation | Token missing → SignIn; token present → RoleRouter → correct shell |
| Session persistence | token + userId + role + apiBase stored in SharedPreferences |
| Incident tap-to-detail | Command dashboard only; loads `GET /incidents/{id}` on tap |
| Scenario runner | Command only; dropdown menu → POST /scenarios/{id}/run → snackbar result |

---

## 10. Screen Inventory (Complete)

| Screen | Route | Role | Tabs/Views |
|---|---|---|---|
| Sign In | `/` | All | Step 1: phone + API · Step 2: OTP + role |
| Citizen Home (Map) | tab 0 | Citizen | Map + incident list |
| Citizen Report | tab 1 | Citizen | Category + description + evidence + submit |
| Citizen Alerts | tab 2 | Citizen | Alert card list with retraction support |
| Citizen Verify | tab 3 | Citizen | Confirm/dispute nearby incidents |
| Responder Queue | tab 0 | Responder | Asset selector + dispatch card list |
| Responder Status | tab 1 | Responder | Availability selector + submit |
| Command Dashboard | full-screen | Command | Map + incidents + trace feed + resource gauges |

---

## 11. Responsive Breakpoints

| Breakpoint | Layout |
|---|---|
| < 1100px (mobile) | Single-column; Command uses OPS/TRACE tabs |
| ≥ 1100px (desktop/web) | Two-column (60/40 split) for Command dashboard; Citizen/Responder remain single-column |

---

## 12. Empty / Loading / Error State Matrix

| Screen | Loading | Empty | Error |
|---|---|---|---|
| Citizen Map | 3× SkeletonLoader | `— No active incidents in your area.` | Crimson ErrorBox + Retry |
| Citizen Alerts | 3× SkeletonLoader | `— No alerts yet — run a scenario from Command.` | Crimson ErrorBox + Retry |
| Citizen Verify | Centered spinner | `— No incidents nearby to verify.` | Snackbar on submit fail |
| Responder Queue | Centered spinner | `— Queue is clear. No dispatches for {asset}.` | Crimson ErrorBox + Retry |
| Command Dashboard | SkeletonLoader (detail) | `— No active incidents.` | ErrorBox inline in left pane |
| Command Trace | — | `— Waiting for pipeline events.` | DISCONNECTED badge |
