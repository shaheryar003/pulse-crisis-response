"""Agent base + standard artifact envelope.

Every specialist emits a dict that conforms to ``Envelope`` so traces are uniform
(this is what makes the Antigravity-style trace legible to judges).
"""
from __future__ import annotations

import json
import time
import uuid
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, ClassVar


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def new_id(prefix: str = "id") -> str:
    return f"{prefix}_{uuid.uuid4().hex[:10]}"


@dataclass
class Envelope:
    """The canonical artifact envelope.

    Mirrors the JSON contract in ``sprints/methodology.md``.
    """
    agent: str
    tier: int
    run_id: str
    ts: str
    inputs_summary: dict[str, Any] = field(default_factory=dict)
    evidence: list[dict[str, Any]] = field(default_factory=list)
    hypothesis: str | None = None
    confidence: float = 0.0
    decision: str = ""
    alternatives_considered: list[str] = field(default_factory=list)
    next_action: str = ""
    side_effects: list[dict[str, Any]] = field(default_factory=list)
    skill_version: str = "1.0.0"

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class ArtifactSink:
    """Writes artifacts to disk + buffers them for the WS trace stream."""
    root: Path
    in_memory: list[dict[str, Any]] = field(default_factory=list)

    def write(self, tier_name: str, payload: dict[str, Any]) -> str:
        run_root = self.root / payload.get("run_id", "run_unknown") / tier_name
        run_root.mkdir(parents=True, exist_ok=True)
        artifact_id = payload.get("id") or new_id("art")
        path = run_root / f"{artifact_id}.json"
        path.write_text(json.dumps(payload, default=str, indent=2), encoding="utf-8")
        self.in_memory.append(payload)
        return str(path)

    def drain(self) -> list[dict[str, Any]]:
        out = list(self.in_memory)
        self.in_memory.clear()
        return out


class Agent:
    """Lightweight base. Each specialist overrides ``run``."""

    tier: ClassVar[int] = 0
    name: ClassVar[str] = "agent"

    def __init__(self, sink: ArtifactSink, run_id: str | None = None):
        self.sink = sink
        self.run_id = run_id or new_id("run")

    def envelope(self, **kwargs: Any) -> Envelope:
        return Envelope(
            agent=self.name,
            tier=self.tier,
            run_id=self.run_id,
            ts=iso_now(),
            **kwargs,
        )

    def emit(self, tier_name: str, payload: dict[str, Any]) -> str:
        payload.setdefault("run_id", self.run_id)
        payload.setdefault("ts", iso_now())
        return self.sink.write(tier_name, payload)

    def run(self, *args: Any, **kwargs: Any) -> Any:  # pragma: no cover
        raise NotImplementedError


class Timer:
    def __init__(self) -> None:
        self.t0: float = 0.0
        self.elapsed_ms: int = 0

    def __enter__(self) -> "Timer":
        self.t0 = time.perf_counter()
        return self

    def __exit__(self, *_: Any) -> None:
        self.elapsed_ms = int((time.perf_counter() - self.t0) * 1000)
