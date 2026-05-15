"""Incident query endpoints."""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request

router = APIRouter(prefix="/incidents", tags=["incidents"])


@router.get("", summary="List active incidents")
def list_incidents(request: Request, status: str = "active", zone: str | None = None, limit: int = 50) -> dict:
    rows = request.app.state.store.list_incidents(status=status, zone=zone, limit=limit)
    return {"count": len(rows), "incidents": rows}


@router.get("/{incident_id}", summary="Incident detail")
def get_incident(incident_id: str, request: Request) -> dict:
    inc = request.app.state.store.get_incident(incident_id)
    if not inc:
        raise HTTPException(status_code=404, detail="incident_not_found")
    audit = request.app.state.store.audit_for_incident(incident_id)
    return {"incident": inc, "audit_trail": audit}
