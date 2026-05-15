"""Scenario control endpoints (demo orchestration)."""
from __future__ import annotations

import json
from pathlib import Path

from fastapi import APIRouter, HTTPException, Request

from ..agents.base import ArtifactSink, new_id
from ..agents.commander import Commander
from ..services import loader

REPO_ROOT = Path(__file__).resolve().parents[3]

router = APIRouter(prefix="/scenarios", tags=["scenarios"])


@router.get("", summary="List available scenarios")
def list_scenarios() -> dict:
    sc_dir = REPO_ROOT / "scenarios"
    out = []
    for p in sorted(sc_dir.glob("scenario_*.json")):
        try:
            j = json.loads(p.read_text(encoding="utf-8"))
            out.append({"id": j.get("id"), "name": j.get("name"), "path": str(p.name)})
        except Exception:
            pass
    return {"count": len(out), "scenarios": out}


@router.post("/{scenario_id}/run", summary="Run a scenario through the pipeline")
async def run_scenario(scenario_id: str, request: Request) -> dict:
    sc_dir = REPO_ROOT / "scenarios"
    path = next((p for p in sc_dir.glob("scenario_*.json") if json.loads(p.read_text(encoding="utf-8")).get("id") == scenario_id), None)
    if path is None:
        raise HTTPException(status_code=404, detail="scenario_not_found")
    sc = json.loads(path.read_text(encoding="utf-8"))

    state = request.app.state
    sink = ArtifactSink(root=state.artifact_root)
    cmd = Commander(sink=sink)

    social_refs = []
    recovery_reports: list[dict] = []
    traffic_overlay: list[dict] = []
    for ev in sc.get("events", []):
        payload = ev.get("payload", {})
        if ev["kind"] == "social_post" and payload.get("signal_id_ref"):
            p = loader.social_post_by_id(payload["signal_id_ref"])
            if p:
                social_refs.append(p)
        elif ev["kind"] == "field_report":
            # Field reports drive the recovery loop so the audit chain is visible.
            recovery_reports.append(payload)
        elif ev["kind"] == "traffic_tick":
            traffic_overlay.append(payload)

    weather_mode = sc.get("api_overrides", {}).get("weather", "live")
    weather_overrides = sc.get("weather_overrides", {})

    result = cmd.run_round(
        social_posts=social_refs or None,
        sensor_readings=loader.sensor_readings(),
        weather_mode=weather_mode,
        weather_overrides=weather_overrides,
        traffic_overlay=traffic_overlay,
        recovery_field_reports=recovery_reports or None,
    )

    # Persist incidents/dispatches/alerts so /incidents and /dispatch reflect state.
    for inc in result["incidents"]:
        state.store.upsert_incident(inc)
    for ticket in result["dispatches"]:
        state.store.insert_dispatch(ticket)
    for msg in result["messages"]:
        msg_for_store = {
            "alert_id": new_id("al"),
            "incident_id": msg["incident_id"],
            "channel": msg["channel"],
            "body_en": msg.get("body_en"),
            "body_ur": msg.get("body_ur"),
            "delivery": msg.get("delivery", {}),
            "status": "staged" if msg.get("requires_human_approval") else "sent",
            **msg,
        }
        state.store.insert_alert(msg_for_store)
    for rcl in result["recall"]:
        state.store.append_audit(
            audit_id=rcl["audit"]["audit_id"],
            incident_id=rcl["incident_id"],
            actor="recall-agent",
            action="retract",
            payload=rcl["audit"],
        )
        # Retract previously sent public alerts on this incident
        for al in state.store.list_alerts(incident_id=rcl["incident_id"]):
            if al["channel"] == "public_push":
                state.store.retract_alert(al["alert_id"])
        state.store.update_incident_status(rcl["incident_id"], "retracted")

    # Publish each artifact onto the WS bus for live trace
    for art in sink.drain():
        await state.bus.publish({"type": "artifact", "payload": art})

    return {
        "scenario_id": scenario_id,
        "round_id": result["round"]["round_id"],
        "incidents": [inc["classification"] for inc in result["incidents"]],
        "dispatches": len(result["dispatches"]),
        "messages": len(result["messages"]),
        "recall": len(result["recall"]),
    }
