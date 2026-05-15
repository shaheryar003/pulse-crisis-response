---
name: severity-forecaster
description: Predicts affected radius, population, peak time, duration, spread risk with uncertainty bands. Activate after Classifier.
metadata:
  type: forecaster
  version: 1.0.0
  tier: 4
---

# Severity & Evolution Forecaster

## Inputs
- Classifier output.
- Historical context from HistoricalAgent.
- Vulnerability data from HistoricalAgent.
- Real-time signals (rainfall rate, sensor values).

## Procedure

### 1. Type-specific propagation models
| Type | Radius growth | Duration |
|---|---|---|
| flood | r(t) = sqrt(rain_mmhr * t / 30) * 0.4 km | until rain stops + 90 min drain |
| heatwave | static zone | until temp drops below threshold for 2h |
| fire | r(t) = wind_kmh * t / 60 * 0.1 km | until response success |
| water_main | static localized | 3–8h repair |
| power_outage | bounded by feeder topology | 1–6h |
| accident | static | 30–90 min |

### 2. Population estimation
Multiply final radius polygon area by zone density (from vulnerability data). Sum across overlapping zones.

### 3. Peak time
Type-specific: floods peak as drainage saturates; heatwave at solar maximum; outages at affected user count plateau.

### 4. Uncertainty
Monte Carlo 200 samples over input distributions (rain rate ±10%, density ±20%, response time ±25%). Report p10/p50/p90.

### 5. Spread risk
- High if hypothesis is `fire` or `disease_cluster`.
- Medium for `flood` with > 30mm/hr.
- Low otherwise.

## Emit
```json
{
  "agent": "severity-forecaster",
  "incident_id": "...",
  "ts": "...",
  "radius_km": {"p10": 1.4, "p50": 1.8, "p90": 2.5},
  "pop_affected": {"p10": 18000, "p50": 28000, "p90": 41000},
  "peak_eta_min": 45,
  "duration_min": {"p10": 180, "p50": 360, "p90": 540},
  "spread_risk": "medium",
  "vulnerable_pop_pct": 0.22,
  "envelope": { "tier": 4, "decision": "forecast_complete", "confidence": 0.72 }
}
```

## Rules
1. Always emit uncertainty bands. Single-point estimates are forbidden.
2. Population estimate must reference zone polygons, not just centroid buffer.
3. If propagation model uncertain → widen p10/p90 explicitly.

## Failure Modes
- Missing rain rate for flood: assume 25mm/hr (median historical), flag.
- Unknown zone density: use city average, flag.
