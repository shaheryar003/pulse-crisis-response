# Data & Stream Schemas

All agent artifacts share a common envelope (see `sprints/methodology.md`).

## Tier-1 signal envelopes

### Social post
```json
{"agent": "social-agent", "tier": 1, "signal_id": "soc_<uuid>",
 "source_post_id": "...", "lang": "en|ur|ur-roman",
 "geo": {"lat": ..., "lon": ..., "confidence": 0.0-1.0},
 "zone_match": "G-10",
 "keywords": ["flood"], "urgency": 0.0-1.0,
 "credibility": 0.0-1.0, "media_attached": bool,
 "user_id_hash": "...", "decision": "accept|unverified|drop",
 "envelope": {...}}
```
Credibility formula: `0.25*verified + 0.20*log10_followers/6 + 0.15*age_norm + 0.20*geo_conf + 0.10*urgency - 0.20*contradiction`.

### Weather
```json
{"agent": "weather-agent", "tier": 1, "signal_id": "wx_<ts>",
 "zone": "...", "source": "openweathermap|cache",
 "stale_minutes": 0|<int>,
 "vars": {"rain_mmhr": 47, "heat_index_c": ..., "wind_kmh": ..., "aqi": ...},
 "triggers": ["flood_risk"|"heat_critical"|...]}
```

### Traffic
```json
{"agent": "traffic-agent", "tier": 1, "signal_id": "trf_<ts>",
 "corridor_id": "c_margalla", "from_node": "F-8", "to_node": "G-10",
 "baseline_eta_s": 480, "current_eta_s": 1620, "delta": 2.375,
 "trigger": "severe_congestion|congestion_spike"}
```

### Sensor (IoT)
```json
{"agent": "sensor-agent", "tier": 1, "signal_id": "sns_<sensor>_<ts>",
 "sensor_id": "ws_g10_a", "type": "water_level|aqi|transformer_load|smoke|heat_index|structural_strain",
 "zone": "G-10", "value": 92.4, "threshold": 80, "consecutive_breaches": 3}
```

### Citizen field report
```json
{"agent": "citizen-report-agent", "tier": 1, "signal_id": "rpt_<uuid>",
 "category": "flood|fire|...", "zone": "G-10",
 "credibility": 0.0-1.0, "media_evidence": ["photo:present"],
 "transcription": "...", "user_id_hash": "...",
 "expert_correction": bool}
```

### Historical context
```json
{"agent": "historical-agent", "tier": 1, "zone": "G-10",
 "vulnerability_index": 0.0-1.0,
 "factors": {"hospital_density_per_10k": ..., "evacuation_routes": ...},
 "history_summary": {"freq_per_year": ..., "avg_duration_h": ...},
 "historical_examples": ["..."]}
```

## Tier-2 candidate
```json
{"agent": "fusion-agent", "candidate_id": "cand_<uuid>",
 "zone": "...", "centroid": {"lat": ..., "lon": ...},
 "signal_ids": [...], "source_types": ["social", "weather"],
 "diversity_score": 0.67, "avg_credibility": 0.74,
 "hypothesis_seed": "flood",
 "decision": "candidate_formed|weak_candidate"}
```

## Tier-3 classification
```json
{"agent": "classifier-agent", "incident_id": "inc_<uuid>",
 "zone": "G-10", "type": "flood", "severity": 4, "confidence": 0.78,
 "ensemble_votes": [{"type": "...", "severity": ...}, ...],
 "rationale": "...", "low_confidence": bool}
```

## Tier-4 forecast
```json
{"agent": "severity-forecaster", "incident_id": "...",
 "radius_km": {"p10": ..., "p50": ..., "p90": ...},
 "pop_affected": {"p10": ..., "p50": ..., "p90": ...},
 "peak_eta_min": 45, "duration_min": {"p10": ..., "p50": ..., "p90": ...},
 "spread_risk": "low|medium|high",
 "vulnerability_index": 0.0-1.0}
```

## Tier-5 priority
```json
{"agent": "prioritizer", "round_id": "round_<uuid>",
 "ranking": [
   {"incident_id": "...", "rank": 1, "priority": 0.82,
    "rationale": "Ranked 1 because severity=4 + 28k affected + medium spread.",
    "recommended_resource_share": 0.62, "floor_assignment": true}
 ],
 "trade_offs": ["G-10 takes ~62% of assets..."],
 "resource_shortfall": false}
```

## Tier-5 allocation
```json
{"agent": "resource-allocator",
 "assignments": [
   {"incident_id": "...", "zone": "G-10",
    "assigned_assets": [{"asset_id": "rescue-3", "type": "rescue", "eta_s": 540, "from": "depot_north", "required": "rescue"}],
    "capability_coverage": 1.0, "unmet": []}
 ],
 "alternatives_considered": ["..."],
 "total_cost": 4860}
```

## Tier-5 simulation (one per action)
```json
{"agent": "simulation-agent", "incident_id": "...", "action_id": "act_<uuid>",
 "action_type": "dispatch|reroute|alert|hospital_prep",
 "before_state": {...}, "action": {...}, "after_state": {...},
 "improvement": {...}, "side_effects": [...],
 "evacuation_jam_probability": 0.0-1.0, "requires_staging": bool}
```

## Tier-6 dispatch ticket
```json
{"agent": "dispatch-agent", "dispatch_id": "disp_<uuid>",
 "incident_id": "...", "asset_id": "rescue-3",
 "destination": {"zone": "G-10", "label": "..."},
 "eta_s": 540, "priority": "urgent|high|normal",
 "instructions": "...", "supports": [...],
 "status": "issued|acked|en_route|on_scene|clear|recalled"}
```

## Tier-6 stakeholder message
```json
{"agent": "stakeholder-comms", "incident_id": "...",
 "channel": "public_push|hospital|utility|traffic_police|media|command_center",
 "lang": "en|ur|both", "body_en": "...", "body_ur": "...",
 "delivery": {"target_radius_km": 2.0, "estimated_recipients": 28000, "staged": bool},
 "requires_human_approval": bool}
```

## Tier-7 recall + audit
```json
{"agent": "recall-agent", "incident_id": "...",
 "audit": {
   "audit_id": "...", "ts_flip": "...",
   "original": {"type": "flood", "severity": 4, "confidence": 0.78, "actions_taken": [...]},
   "new": {"type": "water_main_burst", "severity": 2, "confidence": 0.91},
   "evidence_at_flip": [...],
   "responsible_agent_chain": [...],
   "user_impact": {"recipients_of_retraction": 28000, "responders_recalled": 2}
 },
 "retraction_message_en": "Correction: ...",
 "actions": ["alert_retracted", "responders_reassigned", "audit_logged"]}
```

## Persistence (SQLite)

See `backend/app/db/schema.sql` for canonical table definitions:
- `signals` (agent, tier, zone, credibility, decision, hypothesis, raw_json, ts)
- `incidents` (zone, type, severity, confidence, status, radius_km_p50, pop_p50, duration_min_p50)
- `dispatches` (asset_id, incident_id, status state-machine)
- `alerts` (channel, body_en, body_ur, status: staged|sent|retracted)
- `resources` (asset_id, type, capabilities[], status)
- `audit_log` (append-only, indexed by incident_id)
