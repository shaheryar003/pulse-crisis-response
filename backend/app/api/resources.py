"""Resource roster endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Request

router = APIRouter(prefix="/resources", tags=["resources"])


@router.get("", summary="Asset roster")
def list_resources(request: Request) -> dict:
    rows = request.app.state.store.list_resources()
    return {"count": len(rows), "assets": rows}
