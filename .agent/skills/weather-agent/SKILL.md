---
name: weather-agent
description: Polls weather API for the operational area, identifies threshold-breach events (heavy rain, heat index, wind), emits Tier-1 signals. Falls back to cached data on API failure. Activate on every commander tick or weather-driven scenario.
metadata:
  type: ingest
  version: 1.0.0
  tier: 1
---

# Weather Signal Agent

## Purpose
Detect environmental triggers for crises and surface them with explicit confidence and freshness metadata.

## Inputs
- OpenWeatherMap (primary).
- `sim/streams/weather_cache.json` (fallback).
- Scenario override `scenarios/*.json:weather_overrides`.

## Procedure

### 1. Fetch
Call API with 3s timeout, 2 retries with backoff. On failure → fallback to cache, set `stale_minutes`.

### 2. Threshold rules (Islamabad-tuned)
| Variable | Crisis level | Emission |
|---|---|---|
| Rainfall mm/hr | > 30 = severe flood risk | `flood_risk` |
| Rainfall mm/hr | 15–30 = elevated | `flood_watch` |
| Heat index °C | > 45 = heatwave critical | `heat_critical` |
| Heat index °C | 40–45 = elevated | `heat_watch` |
| Wind gust km/h | > 80 = structural | `wind_risk` |
| AQI | > 300 = hazardous | `air_hazard` |

### 3. Sector mapping
Map weather grid points to sector polygons via point-in-polygon against `sim/fixtures/zones.geojson`.

### 4. Emit artifact
```json
{
  "agent": "weather-agent",
  "signal_id": "wx_<ts>",
  "ts": "...",
  "source": "openweathermap | cache",
  "stale_minutes": 0 | <int>,
  "zone": "...",
  "vars": {"rain_mmhr": 47, "heat_index_c": 32, "wind_kmh": 18, "aqi": 95},
  "triggers": ["flood_risk"],
  "envelope": { "tier": 1, "decision": "accept", "confidence": 0.95 }
}
```

## Rules
1. Always include `stale_minutes`. Downstream agents must derate signal weight if > 15.
2. Never drop a weather signal on API failure — always emit, even if stale.
3. Threshold breach emits a separate signal from baseline reading.

## Failure Modes
- API timeout twice → use cache, `stale_minutes` reflects cache age, emit `degraded` envelope.
- Cache also missing → emit `weather:blackout` signal so PM is aware.
