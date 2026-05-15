"""WebSocket trace endpoint — live stream of agent artifacts."""
from __future__ import annotations

import json

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

router = APIRouter(tags=["trace"])


@router.websocket("/trace")
async def trace_ws(ws: WebSocket) -> None:
    await ws.accept()
    bus = ws.app.state.bus
    queue, replay = await bus.subscribe()
    try:
        for old in replay:
            await ws.send_text(json.dumps(old, default=str))
        while True:
            event = await queue.get()
            await ws.send_text(json.dumps(event, default=str))
    except WebSocketDisconnect:
        pass
    finally:
        bus.unsubscribe(queue)
