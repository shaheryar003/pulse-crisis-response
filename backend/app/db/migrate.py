"""SQLite migration / bootstrap."""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path

from ..services import loader

REPO_ROOT = Path(__file__).resolve().parents[3]
SCHEMA = Path(__file__).parent / "schema.sql"


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(db_path: Path, *, seed: bool = True) -> None:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = connect(db_path)
    try:
        conn.executescript(SCHEMA.read_text(encoding="utf-8"))
        if seed:
            _seed_resources(conn)
            _seed_users(conn)
        conn.commit()
    finally:
        conn.close()


def _seed_resources(conn: sqlite3.Connection) -> None:
    for a in loader.resources():
        conn.execute(
            """
            INSERT OR REPLACE INTO resources(asset_id, type, depot, capabilities, status)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                a["asset_id"],
                a["type"],
                a.get("depot"),
                json.dumps(a.get("capabilities", [])),
                a.get("status", "available"),
            ),
        )


def _seed_users(conn: sqlite3.Connection) -> None:
    seeds = [
        ("u_citizen_demo", "h_03001234567", "citizen", 0.5),
        ("u_responder_demo", "h_03009876543", "responder", 0.9),
        ("u_command_demo", "h_03001112222", "command", 1.0),
    ]
    for uid, ph, role, trust in seeds:
        conn.execute(
            "INSERT OR REPLACE INTO users(user_id, phone_hash, role, trust) VALUES (?,?,?,?)",
            (uid, ph, role, trust),
        )


if __name__ == "__main__":  # pragma: no cover
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(REPO_ROOT / "pulse.db"))
    args = parser.parse_args()
    init_db(Path(args.db))
    print(f"initialized {args.db}")
