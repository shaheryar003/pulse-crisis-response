"""In-process pub/sub for streaming agent artifacts to WS subscribers."""
from __future__ import annotations

import asyncio
from collections import deque
from typing import Any


class TraceBus:
    def __init__(self, max_replay: int = 256):
        self._subscribers: list[asyncio.Queue] = []
        self._replay: deque[dict[str, Any]] = deque(maxlen=max_replay)

    async def publish(self, event: dict[str, Any]) -> None:
        self._replay.append(event)
        for q in list(self._subscribers):
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:  # pragma: no cover - safety
                pass

    def publish_sync(self, event: dict[str, Any]) -> None:
        """Use from sync code (e.g. inside agent emit hook)."""
        self._replay.append(event)
        for q in list(self._subscribers):
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:  # pragma: no cover
                pass

    async def subscribe(self) -> tuple[asyncio.Queue, list[dict[str, Any]]]:
        q: asyncio.Queue = asyncio.Queue(maxsize=1024)
        self._subscribers.append(q)
        return q, list(self._replay)

    def unsubscribe(self, q: asyncio.Queue) -> None:
        try:
            self._subscribers.remove(q)
        except ValueError:
            pass


_BUS: TraceBus | None = None


def get_bus() -> TraceBus:
    global _BUS
    if _BUS is None:
        _BUS = TraceBus()
    return _BUS
