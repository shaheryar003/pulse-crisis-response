"""Lightweight DB store wrapping SQLite. Thread-safe via per-call connections."""
from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

from .migrate import connect


class Store:
    def __init__(self, db_path: Path):
        self.db_path = Path(db_path)

    @contextmanager
    def cursor(self) -> Iterator[sqlite3.Cursor]:
        conn = connect(self.db_path)
        try:
            yield conn.cursor()
            conn.commit()
        finally:
            conn.close()

    # --- signals ---
    def insert_signal(self, signal: dict) -> None:
        with self.cursor() as cur:
            cur.execute(
                """
                INSERT OR REPLACE INTO signals
                (signal_id, agent, tier, zone, credibility, decision, hypothesis, raw_json, ts)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    signal.get("signal_id"),
                    signal.get("agent"),
                    int(signal.get("tier", 1)),
                    signal.get("zone") or signal.get("zone_match"),
                    signal.get("credibility") or signal.get("confidence"),
                    signal.get("decision"),
                    (signal.get("envelope") or {}).get("hypothesis"),
                    json.dumps(signal, default=str),
                    signal.get("ts"),
                ),
            )

    # --- incidents ---
    def upsert_incident(self, incident: dict) -> None:
        cls = incident["classification"]
        fc = incident["forecast"]
        with self.cursor() as cur:
            cur.execute(
                """
                INSERT INTO incidents (incident_id, zone, type, severity, confidence,
                                        radius_km_p50, pop_p50, duration_min_p50, raw_json)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(incident_id) DO UPDATE SET
                    severity=excluded.severity,
                    confidence=excluded.confidence,
                    radius_km_p50=excluded.radius_km_p50,
                    pop_p50=excluded.pop_p50,
                    duration_min_p50=excluded.duration_min_p50,
                    raw_json=excluded.raw_json,
                    updated_at=datetime('now')
                """,
                (
                    cls["incident_id"], cls["zone"], cls["type"], cls["severity"], cls["confidence"],
                    fc["radius_km"]["p50"], fc["pop_affected"]["p50"], fc["duration_min"]["p50"],
                    json.dumps({"classification": cls, "forecast": fc}, default=str),
                ),
            )

    def list_incidents(self, *, status: str | None = "active", zone: str | None = None, limit: int = 50) -> list[dict]:
        clauses = []
        args: list = []
        if status:
            clauses.append("status = ?")
            args.append(status)
        if zone:
            clauses.append("zone = ?")
            args.append(zone)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        with self.cursor() as cur:
            rows = cur.execute(
                f"SELECT * FROM incidents {where} ORDER BY updated_at DESC LIMIT ?", (*args, limit)
            ).fetchall()
        return [self._row_to_incident(r) for r in rows]

    def get_incident(self, incident_id: str) -> dict | None:
        with self.cursor() as cur:
            row = cur.execute("SELECT * FROM incidents WHERE incident_id=?", (incident_id,)).fetchone()
        return self._row_to_incident(row) if row else None

    def update_incident_status(self, incident_id: str, status: str) -> None:
        with self.cursor() as cur:
            cur.execute(
                "UPDATE incidents SET status=?, updated_at=datetime('now') WHERE incident_id=?",
                (status, incident_id),
            )

    @staticmethod
    def _row_to_incident(r: sqlite3.Row) -> dict:
        d = dict(r)
        if d.get("raw_json"):
            try:
                d["details"] = json.loads(d["raw_json"])
            except Exception:
                d["details"] = None
        return d

    # --- dispatches ---
    def insert_dispatch(self, ticket: dict) -> None:
        with self.cursor() as cur:
            cur.execute(
                """
                INSERT OR REPLACE INTO dispatches
                (dispatch_id, incident_id, asset_id, priority, eta_s, instructions, status, raw_json)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    ticket["dispatch_id"], ticket["incident_id"], ticket["asset_id"],
                    ticket.get("priority", "normal"), ticket.get("eta_s"),
                    ticket.get("instructions"), ticket.get("status", "issued"),
                    json.dumps(ticket, default=str),
                ),
            )

    def list_dispatches(self, *, asset_id: str | None = None, incident_id: str | None = None, status: str | None = None) -> list[dict]:
        clauses, args = [], []
        if asset_id:
            clauses.append("asset_id = ?")
            args.append(asset_id)
        if incident_id:
            clauses.append("incident_id = ?")
            args.append(incident_id)
        if status:
            clauses.append("status = ?")
            args.append(status)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        with self.cursor() as cur:
            rows = cur.execute(
                f"SELECT * FROM dispatches {where} ORDER BY issued_at DESC", args
            ).fetchall()
        return [dict(r) for r in rows]

    def update_dispatch_status(self, dispatch_id: str, status: str) -> None:
        with self.cursor() as cur:
            cur.execute(
                "UPDATE dispatches SET status=?, updated_at=datetime('now') WHERE dispatch_id=?",
                (status, dispatch_id),
            )

    # --- alerts ---
    def insert_alert(self, alert: dict) -> None:
        with self.cursor() as cur:
            cur.execute(
                """
                INSERT OR REPLACE INTO alerts
                (alert_id, incident_id, channel, body_en, body_ur, target_radius_km, estimated_recipients, status, raw_json)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    alert["alert_id"], alert["incident_id"], alert["channel"],
                    alert.get("body_en"), alert.get("body_ur"),
                    (alert.get("delivery") or {}).get("target_radius_km"),
                    (alert.get("delivery") or {}).get("estimated_recipients"),
                    alert.get("status", "staged"),
                    json.dumps(alert, default=str),
                ),
            )

    def list_alerts(self, *, incident_id: str | None = None, status: str | None = None) -> list[dict]:
        clauses, args = [], []
        if incident_id:
            clauses.append("incident_id = ?")
            args.append(incident_id)
        if status:
            clauses.append("status = ?")
            args.append(status)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        with self.cursor() as cur:
            rows = cur.execute(
                f"SELECT * FROM alerts {where} ORDER BY issued_at DESC", args
            ).fetchall()
        return [dict(r) for r in rows]

    def retract_alert(self, alert_id: str) -> None:
        with self.cursor() as cur:
            cur.execute(
                "UPDATE alerts SET status='retracted', retracted_at=datetime('now') WHERE alert_id=?",
                (alert_id,),
            )

    # --- resources ---
    def list_resources(self) -> list[dict]:
        with self.cursor() as cur:
            rows = cur.execute("SELECT * FROM resources").fetchall()
        out = []
        for r in rows:
            d = dict(r)
            try:
                d["capabilities"] = json.loads(d["capabilities"]) if d.get("capabilities") else []
            except Exception:
                d["capabilities"] = []
            out.append(d)
        return out

    # --- audit ---
    def append_audit(self, *, audit_id: str, incident_id: str | None, actor: str, action: str, payload: dict | None = None) -> None:
        with self.cursor() as cur:
            cur.execute(
                "INSERT INTO audit_log (audit_id, incident_id, actor, action, payload) VALUES (?, ?, ?, ?, ?)",
                (audit_id, incident_id, actor, action, json.dumps(payload or {}, default=str)),
            )

    def audit_for_incident(self, incident_id: str) -> list[dict]:
        with self.cursor() as cur:
            rows = cur.execute(
                "SELECT * FROM audit_log WHERE incident_id=? ORDER BY ts ASC", (incident_id,)
            ).fetchall()
        return [dict(r) for r in rows]
