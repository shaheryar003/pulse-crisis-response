"""Scenario replay engine.

Reads a scenario manifest, materializes events in simulated time, and emits them
as Tier-1 signal envelopes onto the in-process event bus (or stdout for --dry-run).
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable

REPO_ROOT = Path(__file__).resolve().parents[3]


@dataclass
class ReplayEvent:
    offset_min: float
    kind: str
    payload: dict = field(default_factory=dict)


@dataclass
class Scenario:
    id: str
    name: str
    description: str
    start_ts: str
    duration_min: int = 30
    api_overrides: dict = field(default_factory=dict)
    weather_overrides: dict = field(default_factory=dict)
    events: list[ReplayEvent] = field(default_factory=list)
    expected: dict = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "Scenario":
        raw = json.loads(path.read_text(encoding="utf-8"))
        events = [ReplayEvent(**e) for e in raw.get("events", [])]
        return cls(
            id=raw["id"],
            name=raw["name"],
            description=raw["description"],
            start_ts=raw["start_ts"],
            duration_min=raw.get("duration_min", 30),
            api_overrides=raw.get("api_overrides", {}),
            weather_overrides=raw.get("weather_overrides", {}),
            events=events,
            expected=raw.get("expected", {}),
        )


class ReplayEngine:
    """Deterministic scenario replay.

    Modes:
      - ``acceleration``: float multiplier (e.g. 60.0 plays 60x faster).
      - ``dry_run``: yields events synchronously, prints, no real wall-clock waits.
    """

    def __init__(self, scenario: Scenario, acceleration: float = 60.0):
        self.scenario = scenario
        self.acceleration = max(0.001, acceleration)
        self._paused = asyncio.Event()
        self._paused.set()  # start unpaused

    def pause(self) -> None:
        self._paused.clear()

    def resume(self) -> None:
        self._paused.set()

    async def stream(self, sink: Callable[[dict], Any]) -> None:
        sorted_events = sorted(self.scenario.events, key=lambda e: e.offset_min)
        t0 = time.monotonic()
        for ev in sorted_events:
            target_real_s = (ev.offset_min * 60.0) / self.acceleration
            now = time.monotonic() - t0
            wait = target_real_s - now
            if wait > 0:
                await asyncio.sleep(wait)
            await self._paused.wait()
            envelope = self._wrap(ev)
            result = sink(envelope)
            if asyncio.iscoroutine(result):
                await result

    def dry_run(self, sink: Callable[[dict], Any] | None = None) -> list[dict]:
        out: list[dict] = []
        for ev in sorted(self.scenario.events, key=lambda e: e.offset_min):
            envelope = self._wrap(ev)
            out.append(envelope)
            if sink is not None:
                sink(envelope)
        return out

    def _wrap(self, ev: ReplayEvent) -> dict:
        return {
            "scenario_id": self.scenario.id,
            "offset_min": ev.offset_min,
            "kind": ev.kind,
            "payload": ev.payload,
            "api_overrides": self.scenario.api_overrides,
        }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Replay a crisis scenario")
    parser.add_argument("--scenario", required=True, help="Path to scenario JSON")
    parser.add_argument("--dry-run", action="store_true", help="No wall-clock waits; print events")
    parser.add_argument("--acceleration", type=float, default=60.0)
    parser.add_argument("--validate", action="store_true", help="Validate manifest and exit 0")
    args = parser.parse_args(argv)

    path = Path(args.scenario)
    if not path.is_absolute():
        path = REPO_ROOT / path
    if not path.exists():
        print(f"Scenario not found: {path}", file=sys.stderr)
        return 2

    scenario = Scenario.load(path)
    print(f"[replay] loaded scenario {scenario.id} ({scenario.name}) with {len(scenario.events)} events")
    if args.validate:
        print("[replay] manifest is valid")
        return 0

    engine = ReplayEngine(scenario, acceleration=args.acceleration)

    if args.dry_run:
        events = engine.dry_run(sink=lambda e: print(json.dumps(e)))
        print(f"[replay] dry-run emitted {len(events)} events", file=sys.stderr)
        return 0

    asyncio.run(engine.stream(sink=lambda e: print(json.dumps(e))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
