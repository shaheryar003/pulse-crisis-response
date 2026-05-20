"""Signal ingest endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from ..agents.base import ArtifactSink, new_id
from ..agents.commander import Commander
from ..agents.ingest.citizen import CitizenReportAgent
from ..agents.ingest.social import SocialAgent

router = APIRouter(prefix="/signals", tags=["signals"])


class CitizenReport(BaseModel):
    report_id: str | None = None
    user_id: str
    category: str
    description: str = ""
    geo: dict
    media: list[dict] = Field(default_factory=list)
    ts: str | None = None
    user_trust: float = 0.4


class SocialPost(BaseModel):
    id: str
    user_id: str
    user_followers: int = 0
    user_verified: bool = False
    account_age_days: int = 0
    geo: dict
    lang: str = "en"
    text: str
    ts: str
    media_urls: list[str] = Field(default_factory=list)


@router.post("/citizen", summary="Submit a citizen field report")
async def submit_citizen(report: CitizenReport, request: Request) -> dict:
    app_state = request.app.state
    agent = CitizenReportAgent(ArtifactSink(root=app_state.artifact_root))
    sig = agent.run([report.model_dump()])[0]
    app_state.store.insert_signal(sig)
    await app_state.bus.publish({"type": "signal", "tier": 1, "agent": "citizen-report-agent", "payload": sig})

    # Run the full pipeline with only this citizen report — suppress all fixture
    # sources so simulation data doesn't bleed into the citizen's alert feed.
    sink = ArtifactSink(root=app_state.artifact_root)
    cmd = Commander(sink=sink)
    result = cmd.run_round(
        citizen_reports=[report.model_dump()],
        social_posts=[],
        sensor_readings=[],
    )
    for inc in result["incidents"]:
        app_state.store.upsert_incident(inc)
    for ticket in result["dispatches"]:
        app_state.store.insert_dispatch(ticket)
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
        app_state.store.insert_alert(msg_for_store)
    for art in sink.drain():
        await app_state.bus.publish({"type": "artifact", "payload": art})

    # Recovery hint: if this is an expert correction, trigger a recovery round.
    if sig.get("expert_correction"):
        app_state.pending_recovery.append(report.model_dump())
    return sig


@router.post("/social", summary="Submit a social post (mobile/dev tool)")
async def submit_social(post: SocialPost, request: Request) -> dict:
    app_state = request.app.state
    agent = SocialAgent(ArtifactSink(root=app_state.artifact_root))
    sig = agent.run([post.model_dump()])[0]
    app_state.store.insert_signal(sig)
    await app_state.bus.publish({"type": "signal", "tier": 1, "agent": "social-agent", "payload": sig})
    return sig
