"""FastAPI app factory + lifecycle."""
from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import alerts, auth, dispatch, incidents, resources, scenarios, signals, trace_ws
from .api.trace_bus import get_bus
from .db.migrate import init_db
from .db.store import Store

REPO_ROOT = Path(__file__).resolve().parents[2]


@asynccontextmanager
async def lifespan(app: FastAPI):  # pragma: no cover - exercised by integration tests
    db_path = Path(app.state.db_path) if hasattr(app.state, "db_path") else REPO_ROOT / "pulse.db"
    init_db(db_path)
    app.state.store = Store(db_path)
    app.state.bus = get_bus()
    app.state.artifact_root = REPO_ROOT / "artifacts"
    app.state.pending_recovery = []
    yield


def create_app(*, db_path: str | None = None) -> FastAPI:
    app = FastAPI(
        title="Pulse — Urban Crisis Response",
        version="0.1.0",
        summary="Multi-agent crisis detection, allocation, and recovery for Pakistani cities.",
        lifespan=lifespan,
    )
    if db_path:
        app.state.db_path = db_path
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
        allow_credentials=False,
    )
    app.include_router(auth.router)
    app.include_router(signals.router)
    app.include_router(incidents.router)
    app.include_router(resources.router)
    app.include_router(dispatch.router)
    app.include_router(alerts.router)
    app.include_router(scenarios.router)
    app.include_router(trace_ws.router)

    @app.get("/health", tags=["meta"])
    def health() -> dict:
        return {"status": "ok"}

    return app


app = create_app()
