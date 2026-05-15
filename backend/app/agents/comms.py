"""StakeholderCommsAgent (Tier 6) — 6-channel tailored messaging."""
from __future__ import annotations

import json
from typing import Iterable

from .base import Agent
from ..services.llm import get_llm


PUBLIC_PUSH_EN = {
    "flood": "⚠️ Flooding reported in {zone}. Avoid {road}. Move to higher ground. Helpline: 1122.",
    "heatwave": "🥵 Heat alert {zone}. Stay indoors 11am-4pm. Hydrate. Cooling center at {cooling}.",
    "fire": "🔥 Fire in {zone}. Evacuate immediately. Helpline: 16 (Rescue 1122).",
    "water_main_burst": "💧 Water supply disruption in {zone}. WASA dispatched. Avoid waterlogged streets.",
    "accident": "🚨 Major accident in {zone}. Avoid {road}. Alternate routes via {alt}.",
    "power_outage": "🔌 Power outage in {zone}. IESCO crew dispatched. Critical patients call 118.",
}


class StakeholderCommsAgent(Agent):
    name = "stakeholder-comms"
    tier = 6

    def run(self, *, incidents: list[dict], simulations: list[dict]) -> list[dict]:
        out: list[dict] = []
        sim_by_inc: dict[str, list[dict]] = {}
        for s in simulations:
            sim_by_inc.setdefault(s["incident_id"], []).append(s)

        for inc in incidents:
            cls = inc["classification"]
            fc = inc["forecast"]
            sims = sim_by_inc.get(cls["incident_id"], [])
            staged = any(s.get("requires_staging") for s in sims if s.get("action_type") == "alert")
            for channel in ("public_push", "hospital", "utility", "traffic_police", "media", "command_center"):
                msg = self._render(channel, cls, fc, staged=staged)
                self.emit("comms", msg)
                out.append(msg)
        return out

    def _render(self, channel: str, cls: dict, fc: dict, *, staged: bool) -> dict:
        zone = cls["zone"]
        type_ = cls["type"]
        body_en = ""
        body_ur = ""
        if channel == "public_push":
            template = PUBLIC_PUSH_EN.get(type_, "⚠️ {type} in {zone}. Follow official guidance.")
            body_en = template.format(zone=zone, road="main artery", cooling="nearest cooling center", alt="ring road", type=type_)
            body_ur = get_llm().translate(body_en, to="ur")
        elif channel == "hospital":
            body_en = (
                f"Pre-position trauma capacity for {type_} incident in {zone}. "
                f"Estimated patient surge p50={int(fc['pop_affected']['p50']*0.002)} within {fc['peak_eta_min']} minutes. "
                f"Triage codes: priority red+amber. Coordinate with EMS dispatch."
            )
        elif channel == "utility":
            provider_map = {
                "water_main_burst": "WASA (1334)",
                "power_outage": "IESCO (118)",
                "gas_leak": "SNGPL (1199)",
            }
            provider = provider_map.get(type_, "Pakistan Emergency 1122")
            body_en = f"Escalation: {type_} at {zone}. Asset IDs: pending. Severity {cls['severity']}/5. {provider} — please dispatch crew within 30 min."
        elif channel == "traffic_police":
            body_en = (
                f"Rerouting required around {zone}. Estimated incident radius p50={fc['radius_km']['p50']:.1f} km. "
                f"Block primary arteries within radius; set up diversion using parallel corridors. Duration estimate: {fc['duration_min']['p50']} min."
            )
            body_ur = get_llm().translate(body_en, to="ur")
        elif channel == "media":
            body_en = (
                f"Authorities are responding to a {type_} event in {zone}. "
                f"Source count: multi-agency corroboration; confidence {cls['confidence']}. "
                f"Approximately {fc['pop_affected']['p50']:,} residents may be affected. Updates to follow."
            )
        elif channel == "command_center":
            body_en = json.dumps({
                "incident_id": cls["incident_id"],
                "type": type_,
                "severity": cls["severity"],
                "zone": zone,
                "confidence": cls["confidence"],
                "forecast": fc,
                "staged_alert": staged,
            })
        requires_human = channel == "public_push" and cls["confidence"] < 0.65

        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "incident_id": cls["incident_id"],
            "channel": channel,
            "lang": "both" if body_ur else "en",
            "body_en": body_en,
            "body_ur": body_ur or None,
            "delivery": {
                "target_radius_km": fc["radius_km"]["p50"],
                "estimated_recipients": fc["pop_affected"]["p50"],
                "staged": staged if channel == "public_push" else False,
            },
            "requires_human_approval": requires_human,
            "decision": "drafted",
            "confidence": 0.9,
            "envelope": {
                "agent": self.name,
                "tier": 6,
                "decision": "drafted",
                "confidence": 0.9,
                "hypothesis": type_,
            },
        }
