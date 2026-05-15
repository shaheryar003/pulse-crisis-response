"""Citizen mobile-app field report agent (Tier 1)."""
from __future__ import annotations

import hashlib
from typing import Iterable

from ..base import Agent, new_id
from ...services.geo import zone_for


class CitizenReportAgent(Agent):
    name = "citizen-report-agent"
    tier = 1

    def run(self, reports: Iterable[dict]) -> list[dict]:
        out: list[dict] = []
        for r in reports:
            artifact = self._process(r)
            self.emit("signals/citizen", artifact)
            out.append(artifact)
        return out

    def _process(self, r: dict) -> dict:
        geo = r.get("geo") or {}
        lat, lon = geo.get("lat"), geo.get("lon")
        zone = zone_for(lat, lon) if lat is not None else None
        accuracy_m = geo.get("accuracy_m", 50)
        geo_quality = max(0.0, min(1.0, 1.0 - accuracy_m / 100.0))
        user_trust = float(r.get("user_trust", 0.4))
        media = r.get("media", [])
        media_matches = bool(media)  # mock vision match
        desc = r.get("description", "") or ""
        desc_quality = min(1.0, len(desc) / 80.0)

        cred = (
            0.40 * user_trust
            + 0.30 * (1.0 if media_matches else 0.0)
            + 0.20 * geo_quality
            + 0.10 * desc_quality
        )
        cred = max(0.0, min(1.0, cred))

        expert = user_trust >= 0.85 and r.get("category") in ("infrastructure", "water_main_burst")

        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "signal_id": new_id("rpt"),
            "category": r.get("category"),
            "zone": zone,
            "credibility": round(cred, 3),
            "media_evidence": [f"{m.get('type')}:present" for m in media],
            "transcription": r.get("description"),
            "user_id_hash": hashlib.sha256((r.get("user_id") or "").encode()).hexdigest()[:12],
            "expert_correction": expert,
            "decision": "accept",
            "confidence": round(cred, 3),
            "envelope": {
                "agent": self.name,
                "tier": 1,
                "decision": "accept" if not expert else "expert_correction",
                "confidence": round(cred, 3),
                "hypothesis": r.get("category"),
            },
        }
