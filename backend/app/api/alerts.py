"""Alerts endpoints (citizen app)."""
from __future__ import annotations

from fastapi import APIRouter, Request

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("", summary="Alerts list (optionally near user)")
def list_alerts(request: Request, incident_id: str | None = None, status: str | None = None) -> dict:
    rows = request.app.state.store.list_alerts(incident_id=incident_id, status=status)
    return {"count": len(rows), "alerts": rows}
