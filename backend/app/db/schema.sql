-- Pulse Crisis Response DB Schema (SQLite)
-- Append-only audit_log is the source of truth for retractions/recalls.

CREATE TABLE IF NOT EXISTS users (
    user_id        TEXT PRIMARY KEY,
    phone_hash     TEXT NOT NULL,
    role           TEXT NOT NULL CHECK (role IN ('citizen', 'responder', 'command')),
    trust          REAL NOT NULL DEFAULT 0.40,
    created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS signals (
    signal_id      TEXT PRIMARY KEY,
    agent          TEXT NOT NULL,
    tier           INTEGER NOT NULL,
    zone           TEXT,
    credibility    REAL,
    decision       TEXT,
    hypothesis     TEXT,
    raw_json       TEXT NOT NULL,
    ts             TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS incidents (
    incident_id    TEXT PRIMARY KEY,
    zone           TEXT NOT NULL,
    type           TEXT NOT NULL,
    severity       INTEGER NOT NULL,
    confidence     REAL NOT NULL,
    status         TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'retracted')),
    radius_km_p50  REAL,
    pop_p50        INTEGER,
    duration_min_p50 INTEGER,
    raw_json       TEXT NOT NULL,
    created_at     TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_incidents_status ON incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_zone ON incidents(zone);

CREATE TABLE IF NOT EXISTS dispatches (
    dispatch_id    TEXT PRIMARY KEY,
    incident_id    TEXT NOT NULL,
    asset_id       TEXT NOT NULL,
    priority       TEXT NOT NULL,
    eta_s          INTEGER,
    instructions   TEXT,
    status         TEXT NOT NULL DEFAULT 'issued' CHECK (status IN ('issued','acked','en_route','on_scene','clear','recalled')),
    raw_json       TEXT NOT NULL,
    issued_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_dispatch_asset ON dispatches(asset_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_incident ON dispatches(incident_id);

CREATE TABLE IF NOT EXISTS alerts (
    alert_id       TEXT PRIMARY KEY,
    incident_id    TEXT NOT NULL,
    channel        TEXT NOT NULL,
    body_en        TEXT,
    body_ur        TEXT,
    target_radius_km REAL,
    estimated_recipients INTEGER,
    status         TEXT NOT NULL DEFAULT 'staged' CHECK (status IN ('staged','sent','retracted')),
    raw_json       TEXT NOT NULL,
    issued_at      TEXT NOT NULL DEFAULT (datetime('now')),
    retracted_at   TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_incident ON alerts(incident_id);

CREATE TABLE IF NOT EXISTS resources (
    asset_id       TEXT PRIMARY KEY,
    type           TEXT NOT NULL,
    depot          TEXT,
    capabilities   TEXT,  -- JSON array
    status         TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available','en_route','on_scene','out_of_service'))
);

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id       TEXT PRIMARY KEY,
    incident_id    TEXT,
    actor          TEXT NOT NULL,
    action         TEXT NOT NULL,
    payload        TEXT,
    ts             TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_audit_incident ON audit_log(incident_id);
