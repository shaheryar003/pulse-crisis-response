"""End-to-end demo orchestrator.

Runs one or more scenarios through the Commander and validates the result
against the scenario's `expected` block. Used both for CI verification and
during the recorded demo walkthrough.

Usage:
    python scenarios/run_demo.py --scenario A
    python scenarios/run_demo.py --all
    python scenarios/run_demo.py --scenario A --validate
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from backend.app.agents.base import ArtifactSink  # noqa: E402
from backend.app.agents.commander import Commander  # noqa: E402
from backend.app.services import loader  # noqa: E402


SCENARIOS_DIR = REPO_ROOT / "scenarios"


def load_scenario(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run_scenario(scenario: dict, sink: ArtifactSink) -> dict:
    cmd = Commander(sink=sink)
    social_refs = []
    recovery_reports: list[dict] = []
    traffic_overlay: list[dict] = []
    for ev in scenario.get("events", []):
        payload = ev.get("payload", {})
        if ev["kind"] == "social_post" and payload.get("signal_id_ref"):
            p = loader.social_post_by_id(payload["signal_id_ref"])
            if p:
                social_refs.append(p)
        elif ev["kind"] == "field_report":
            # Field reports drive the recovery loop (post-classification correction).
            recovery_reports.append(payload)
        elif ev["kind"] == "traffic_tick":
            traffic_overlay.append(payload)

    weather_mode = scenario.get("api_overrides", {}).get("weather", "live")
    weather_overrides = scenario.get("weather_overrides", {})

    result = cmd.run_round(
        social_posts=social_refs or None,
        sensor_readings=loader.sensor_readings(),
        weather_mode=weather_mode,
        weather_overrides=weather_overrides,
        traffic_overlay=traffic_overlay,
        recovery_field_reports=recovery_reports or None,
    )
    return result


def validate(scenario: dict, result: dict) -> tuple[bool, list[str]]:
    expected = scenario.get("expected", {})
    errors: list[str] = []

    expected_incidents = expected.get("incidents", [])
    actual = [inc["classification"] for inc in result["incidents"]]
    for exp in expected_incidents:
        zone = exp.get("zone")
        match = next((a for a in actual if a["zone"] == zone), None)
        if not match:
            errors.append(f"missing incident at zone={zone}")
            continue
        if "type" in exp and match["type"] != exp["type"]:
            errors.append(f"{zone}: expected type {exp['type']}, got {match['type']}")
        if "severity_min" in exp and match["severity"] < exp["severity_min"]:
            errors.append(f"{zone}: severity {match['severity']} < {exp['severity_min']}")
        if "severity_max" in exp and match["severity"] > exp["severity_max"]:
            errors.append(f"{zone}: severity {match['severity']} > {exp['severity_max']}")
        if "confidence_min" in exp and match["confidence"] < exp["confidence_min"]:
            errors.append(f"{zone}: confidence {match['confidence']} < {exp['confidence_min']}")
        if exp.get("type_final"):
            recalls = result.get("recall") or []
            if not recalls:
                errors.append(f"{zone}: expected a recall flip to {exp['type_final']}, none observed")
            else:
                rcl = recalls[0]
                if rcl["audit"]["new"]["type"] != exp["type_final"]:
                    errors.append(f"{zone}: flip ended at {rcl['audit']['new']['type']}, expected {exp['type_final']}")

    dispatches_min = expected.get("dispatches_min")
    if dispatches_min is not None and len(result["dispatches"]) < dispatches_min:
        errors.append(f"dispatches {len(result['dispatches'])} < {dispatches_min}")
    recalls_expected = expected.get("recalls")
    if recalls_expected is not None and len(result["recall"]) < recalls_expected:
        errors.append(f"recalls {len(result['recall'])} < {recalls_expected}")

    return (len(errors) == 0, errors)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scenario", help="Single scenario ID (A/B/C/D)")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--validate", action="store_true", help="Validate against expected block; exit 1 on failure")
    parser.add_argument("--out", default="artifacts/demo")
    args = parser.parse_args(argv)

    sink_root = REPO_ROOT / args.out
    sink_root.mkdir(parents=True, exist_ok=True)

    targets: list[Path] = []
    if args.all:
        targets = sorted(SCENARIOS_DIR.glob("scenario_*.json"))
    elif args.scenario:
        for p in SCENARIOS_DIR.glob("scenario_*.json"):
            j = json.loads(p.read_text(encoding="utf-8"))
            if j.get("id") == args.scenario:
                targets = [p]
                break
        if not targets:
            print(f"No scenario found with id {args.scenario}", file=sys.stderr)
            return 2
    else:
        parser.error("specify --scenario or --all")

    overall_ok = True
    for path in targets:
        scenario = load_scenario(path)
        sink = ArtifactSink(root=sink_root / scenario["id"])
        result = run_scenario(scenario, sink)
        ok, errors = validate(scenario, result)
        summary = {
            "scenario": scenario["id"],
            "name": scenario["name"],
            "incidents": [inc["classification"] for inc in result["incidents"]],
            "dispatches": len(result["dispatches"]),
            "messages": len(result["messages"]),
            "recall": len(result["recall"]),
            "validation_ok": ok,
            "errors": errors,
        }
        print(json.dumps(summary, indent=2, default=str))
        if args.validate and not ok:
            overall_ok = False

    return 0 if overall_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
