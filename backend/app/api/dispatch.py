"""Dispatch endpoints (responder app)."""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

router = APIRouter(prefix="/dispatch", tags=["dispatch"])


class StatusUpdate(BaseModel):
    status: str


@router.get("/queue", summary="Pending dispatches for an asset")
def queue(asset_id: str, request: Request) -> dict:
    rows = request.app.state.store.list_dispatches(asset_id=asset_id)
    return {"count": len(rows), "dispatches": rows}


@router.post("/{dispatch_id}/ack", summary="Responder acknowledges")
def ack(dispatch_id: str, request: Request) -> dict:
    request.app.state.store.update_dispatch_status(dispatch_id, "acked")
    return {"dispatch_id": dispatch_id, "status": "acked"}


@router.post("/{dispatch_id}/status", summary="Responder updates status")
def update_status(dispatch_id: str, payload: StatusUpdate, request: Request) -> dict:
    allowed = {"en_route", "on_scene", "clear"}
    if payload.status not in allowed:
        raise HTTPException(status_code=400, detail=f"status must be one of {sorted(allowed)}")
    request.app.state.store.update_dispatch_status(dispatch_id, payload.status)
    return {"dispatch_id": dispatch_id, "status": payload.status}
