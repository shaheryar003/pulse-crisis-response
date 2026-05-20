"""Commander — runs the full crisis pipeline end-to-end.

This is the deployable mirror of ``.agent/skills/commander/SKILL.md``. It can be
invoked directly (CLI) or wrapped by the FastAPI service.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path
from typing import Any, Iterable

from .base import Agent, ArtifactSink, iso_now, new_id
from .ingest.social import SocialAgent
from .ingest.weather import WeatherAgent
from .ingest.traffic import TrafficAgent
from .ingest.sensor import SensorAgent
from .ingest.citizen import CitizenReportAgent
from .ingest.historical import HistoricalAgent
from .fusion import FusionAgent
from .verification import VerificationAgent
from .classifier import ClassifierAgent
from .severity import SeverityForecaster
from .prioritizer import PrioritizerAgent
from .allocator import ResourceAllocator
from .simulation import SimulationAgent
from .dispatch import DispatchAgent
from .comms import StakeholderCommsAgent
from .recall import RecallAgent
from .learning import LearningAgent
from ..services import loader

REPO_ROOT = Path(__file__).resolve().parents[3]


class Commander:
    """Routes signals through tier 1 → 7, emitting artifacts to the sink."""

    def __init__(self, sink: ArtifactSink | None = None) -> None:
        self.sink = sink or ArtifactSink(root=REPO_ROOT / "artifacts")
        self.round_id = new_id("round")

    def run_round(
        self,
        *,
        social_posts: Iterable[dict] | None = None,
        sensor_readings: Iterable[dict] | None = None,
        citizen_reports: Iterable[dict] | None = None,
        weather_mode: str = "live",
        weather_overrides: dict | None = None,
        traffic_overlay: list[dict] | None = None,
        recovery_field_reports: list[dict] | None = None,
        available_assets: int | None = None,
    ) -> dict:
        # --- Tier 1: parallel ingest ---
        run_id = new_id("run")
        social = SocialAgent(self.sink, run_id=run_id)
        weather = WeatherAgent(self.sink, run_id=run_id)
        traffic = TrafficAgent(self.sink, run_id=run_id)
        sensor = SensorAgent(self.sink, run_id=run_id)
        citizen = CitizenReportAgent(self.sink, run_id=run_id)

        social_signals = social.run(list(social_posts) if social_posts is not None else list(loader.social_posts()))
        weather_signals = weather.run(overrides=weather_overrides, api_mode=weather_mode)
        traffic_signals = traffic.run(api_mode="live", overlay=traffic_overlay)
        sensor_signals = sensor.run(list(sensor_readings) if sensor_readings is not None else None)
        citizen_signals = citizen.run(list(citizen_reports) if citizen_reports is not None else [])

        all_signals = (
            list(social_signals)
            + list(weather_signals)
            + list(traffic_signals)
            + list(sensor_signals)
            + list(citizen_signals)
        )

        # --- Tier 2: fusion ---
        fusion = FusionAgent(self.sink, run_id=run_id)
        candidates = fusion.run(all_signals)

        if not candidates:
            return self._idle_round(run_id, all_signals)

        # --- Tier 1.b: historical context per zone ---
        historical = HistoricalAgent(self.sink, run_id=run_id)
        hist_contexts = {c["zone"]: historical.run(zone=c["zone"], incident_type=c["hypothesis_seed"]) for c in candidates}

        # --- Tier 2: verification ---
        verification = VerificationAgent(self.sink, run_id=run_id)
        verified = []
        for cand in candidates:
            cluster_signals = [s for s in all_signals if s.get("signal_id") in cand["signal_ids"]]
            v = verification.run(candidate=cand, contributing_signals=cluster_signals)
            verified.append({"candidate": cand, "verification": v, "signals": cluster_signals})

        # --- Tier 3: classify ---
        classifier = ClassifierAgent(self.sink, run_id=run_id)
        classified = []
        for entry in verified:
            cls = classifier.run(
                candidate=entry["candidate"],
                verification=entry["verification"],
                signals=entry["signals"],
            )
            classified.append({**entry, "classification": cls})

        # --- Tier 4: forecast ---
        forecaster = SeverityForecaster(self.sink, run_id=run_id)
        for entry in classified:
            entry["forecast"] = forecaster.run(incident=entry["classification"], signals=entry["signals"])

        # --- Tier 5: prioritize + allocate + simulate (parallel-shaped) ---
        prioritizer = PrioritizerAgent(self.sink, run_id=run_id)
        allocator = ResourceAllocator(self.sink, run_id=run_id)
        simulator = SimulationAgent(self.sink, run_id=run_id)

        assets = loader.resources()
        avail = available_assets if available_assets is not None else len(assets)
        priority = prioritizer.run(incidents=classified, available_assets=avail)
        # Rebuild a quick incidents-by-id map for downstream tiers.
        incidents_by_id = {entry["classification"]["incident_id"]: entry for entry in classified}
        alloc = allocator.run(ranking=priority["ranking"], assets=assets)
        sims = simulator.run(allocations=alloc["assignments"], incidents_by_id=incidents_by_id)

        # --- Tier 6: dispatch + comms (parallel-shaped) ---
        dispatcher = DispatchAgent(self.sink, run_id=run_id)
        comms = StakeholderCommsAgent(self.sink, run_id=run_id)
        dispatches = dispatcher.run(allocations=alloc["assignments"], incidents_by_id=incidents_by_id)
        messages = comms.run(incidents=list(incidents_by_id.values()), simulations=sims)

        # --- Optional recovery branch ---
        recall_artifacts: list[dict] = []
        if recovery_field_reports:
            citizen_again = CitizenReportAgent(self.sink, run_id=run_id)
            recovery_signals = citizen_again.run(recovery_field_reports)
            verifier_again = VerificationAgent(self.sink, run_id=run_id)
            classifier_again = ClassifierAgent(self.sink, run_id=run_id)
            recall = RecallAgent(self.sink, run_id=run_id)
            for entry in classified:
                priors = entry["classification"]
                combined = entry["signals"] + recovery_signals
                v2 = verifier_again.run(
                    candidate=entry["candidate"],
                    contributing_signals=combined,
                    prior_classification=priors,
                )
                if v2.get("recovery_triggered"):
                    new_cls = classifier_again.run(
                        candidate=entry["candidate"],
                        verification=v2,
                        signals=combined,
                    )
                    rcl = recall.run(
                        original=priors,
                        new_classification=new_cls,
                        contributing_signals=combined,
                        dispatched=[d for d in dispatches if d["incident_id"] == priors["incident_id"]],
                        alerts=[m for m in messages if m["incident_id"] == priors["incident_id"]],
                    )
                    recall_artifacts.append(rcl)

        # --- Tier 7: learning ---
        learner = LearningAgent(self.sink, run_id=run_id)
        round_summary = {
            "run_id": run_id,
            "round_id": self.round_id,
            "incidents": [c["classification"]["incident_id"] for c in classified],
            "dispatches": len(dispatches),
            "alerts": len(messages),
            "recalls": len(recall_artifacts),
        }
        learn = learner.run(round_summary=round_summary, recall=recall_artifacts[0] if recall_artifacts else None)

        # --- Final round artifact ---
        round_artifact = {
            "agent": "commander",
            "round_id": self.round_id,
            "run_id": run_id,
            "ts": iso_now(),
            "tiers_completed": [1, 2, 3, 4, 5, 6, 7],
            "incidents_active": [c["classification"]["incident_id"] for c in classified],
            "summary": round_summary,
            "decision": "round_complete",
            "confidence": 0.9,
        }
        self.sink.write("rounds", round_artifact)
        return {
            "round": round_artifact,
            "incidents": classified,
            "priority": priority,
            "allocations": alloc,
            "simulations": sims,
            "dispatches": dispatches,
            "messages": messages,
            "recall": recall_artifacts,
            "learning": learn,
        }

    def _idle_round(self, run_id: str, signals: list[dict]) -> dict:
        art = {
            "agent": "commander",
            "round_id": self.round_id,
            "run_id": run_id,
            "ts": iso_now(),
            "decision": "no_incident",
            "signal_count": len(signals),
        }
        self.sink.write("rounds", art)
        return {"round": art, "incidents": [], "priority": None, "allocations": None,
                "simulations": [], "dispatches": [], "messages": [], "recall": [], "learning": None}


def _load_scenario(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Pulse Commander")
    parser.add_argument("--scenario", help="Scenario JSON to drive a single round")
    parser.add_argument("--out", default="artifacts", help="Artifact root")
    args = parser.parse_args(argv)

    sink = ArtifactSink(root=Path(args.out).resolve())
    cmd = Commander(sink=sink)

    if not args.scenario:
        print("Running with default fixtures (no scenario specified)...")
        result = cmd.run_round()
    else:
        sc = _load_scenario(REPO_ROOT / args.scenario if not Path(args.scenario).is_absolute() else Path(args.scenario))
        social_refs, citizen_reports = [], []
        sensor_overrides: list[dict] = []
        weather_overrides = sc.get("weather_overrides", {})
        weather_mode = sc.get("api_overrides", {}).get("weather", "live")
        traffic_overlay: list[dict] = []

        for ev in sc.get("events", []):
            payload = ev.get("payload", {})
            if ev["kind"] == "social_post" and payload.get("signal_id_ref"):
                p = loader.social_post_by_id(payload["signal_id_ref"])
                if p:
                    social_refs.append(p)
            elif ev["kind"] == "sensor_reading":
                sensor_overrides.append(payload)
            elif ev["kind"] == "field_report":
                citizen_reports.append(payload)
            elif ev["kind"] == "traffic_tick":
                traffic_overlay.append(payload)

        result = cmd.run_round(
            social_posts=social_refs or None,
            sensor_readings=loader.sensor_readings(),  # full stream for simplicity
            citizen_reports=citizen_reports,
            weather_mode=weather_mode,
            weather_overrides=weather_overrides,
            traffic_overlay=traffic_overlay,
        )

    print(json.dumps({
        "round_id": result["round"]["round_id"],
        "incidents": len(result["incidents"]),
        "dispatches": len(result["dispatches"]),
        "messages": len(result["messages"]),
        "recall": len(result["recall"]),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
