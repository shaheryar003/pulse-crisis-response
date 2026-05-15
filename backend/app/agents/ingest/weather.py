"""Weather signal agent (Tier 1)."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Iterable

from ..base import Agent, new_id, iso_now
from ...services import loader


THRESHOLDS = {
    "rain_mmhr": [(30, "flood_risk"), (15, "flood_watch")],
    "heat_index_c": [(45, "heat_critical"), (40, "heat_watch")],
    "wind_kmh": [(80, "wind_risk")],
    "aqi": [(300, "air_hazard")],
}


def _classify_triggers(vars_: dict) -> list[str]:
    out: list[str] = []
    for key, levels in THRESHOLDS.items():
        v = vars_.get(key)
        if v is None:
            continue
        for thresh, tag in levels:
            if v >= thresh:
                out.append(tag)
                break
    return out


class WeatherAgent(Agent):
    name = "weather-agent"
    tier = 1

    def run(self, *, overrides: dict | None = None, api_mode: str = "live") -> list[dict]:
        """Reads stream + applies scenario overrides; falls back to cache when needed."""
        data, source, stale_min = self._fetch(api_mode)
        out: list[dict] = []

        # City-level signal
        now_vars = data.get("now", {})
        triggers = _classify_triggers(now_vars)
        out.append(self._emit_signal("Islamabad", now_vars, triggers, source, stale_min))

        # Per-grid (per-zone) signals
        for grid in data.get("grid", []):
            zone = grid.get("zone")
            zone_vars = {**now_vars, **grid}
            if overrides and zone in overrides:
                zone_vars.update(overrides[zone])
            t = _classify_triggers(zone_vars)
            if t:
                out.append(self._emit_signal(zone, zone_vars, t, source, stale_min))

        # Forecast triggers
        for f in data.get("forecast_3h", []):
            t = _classify_triggers(f)
            if t:
                f_signal = self._emit_signal("Islamabad", f, t, source, stale_min, forecast_offset=f.get("offset_min"))
                out.append(f_signal)

        return out

    def _fetch(self, api_mode: str) -> tuple[dict, str, int]:
        if api_mode == "down":
            data = loader.weather_cache_fallback()
            return data, "cache", _stale_minutes(data.get("metadata", {}).get("cached_at"))
        if api_mode == "cache":
            data = loader.weather_cache_fallback()
            return data, "cache", _stale_minutes(data.get("metadata", {}).get("cached_at"))
        data = loader.weather_live()
        return data, data.get("metadata", {}).get("source", "live"), 0

    def _emit_signal(self, zone: str, vars_: dict, triggers: list[str], source: str, stale_min: int, *, forecast_offset: int | None = None) -> dict:
        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "signal_id": new_id("wx"),
            "zone": zone,
            "source": source,
            "stale_minutes": stale_min,
            "forecast_offset_min": forecast_offset,
            "vars": {k: vars_.get(k) for k in ("temp_c", "feels_like_c", "heat_index_c", "rain_mmhr", "wind_kmh", "aqi", "humidity_pct")},
            "triggers": triggers,
            "decision": "accept",
            "confidence": 0.95 if stale_min < 15 else 0.7,
            "envelope": {
                "agent": self.name,
                "tier": 1,
                "decision": "accept",
                "confidence": 0.95 if stale_min < 15 else 0.7,
                "hypothesis": triggers[0] if triggers else None,
            },
        }
        self.emit("signals/weather", artifact)
        return artifact


def _stale_minutes(cached_at: str | None) -> int:
    if not cached_at:
        return 999
    try:
        dt = datetime.fromisoformat(cached_at.replace("Z", "+00:00"))
        delta = datetime.now(timezone.utc) - dt
        return max(0, int(delta.total_seconds() / 60))
    except Exception:
        return 999
