"""Signal ingest endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from ..agents.base import ArtifactSink
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
