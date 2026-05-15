"""Social media ingest agent (Tier 1).

Implements the credibility formula from .agent/skills/social-agent/SKILL.md.
"""
from __future__ import annotations

import hashlib
import math
import re
from typing import Iterable

from ..base import Agent, new_id
from ...services.geo import zone_for

CRISIS_KEYWORDS = {
    "en": {
        "flood": "flood", "flooded": "flood", "flooding": "flood", "water": "flood",
        "fire": "fire", "smoke": "fire",
        "accident": "accident", "crash": "accident",
        "blackout": "power_outage", "outage": "power_outage", "power": "power_outage",
        "traffic": "traffic", "jam": "traffic",
        "riot": "public_disorder", "protest": "public_disorder",
        "water main": "water_main_burst", "burst pipe": "water_main_burst", "burst": "water_main_burst",
        "ambulance": "medical", "heat": "heatwave", "heatstroke": "heatwave",
        "gas leak": "gas_leak",
    },
    "ur": {
        "سیلاب": "flood", "آگ": "fire", "حادثہ": "accident",
        "گرمی": "heatwave", "پانی": "flood", "بجلی": "power_outage",
    },
    "ur-roman": {
        "sailab": "flood", "aag": "fire", "hadsa": "accident",
        "garmi": "heatwave", "paani": "flood", "bijli": "power_outage",
        "pipe": "water_main_burst",
    },
}

URGENCY_WORDS = ("urgent", "help", "emergency", "now", "alert", "warning", "هیلپ", "مدد", "behoosh")


def _user_hash(uid: str) -> str:
    return hashlib.sha256(uid.encode("utf-8")).hexdigest()[:12]


def _urgency_score(text: str) -> float:
    low = text.lower()
    hits = sum(1 for w in URGENCY_WORDS if w in low)
    return min(1.0, hits / 3.0)


def _keyword_hits(text: str, lang: str) -> list[str]:
    low = text.lower()
    out: set[str] = set()
    for lng in (lang, "en"):
        for kw, tag in CRISIS_KEYWORDS.get(lng, {}).items():
            if kw in low:
                out.add(tag)
    return sorted(out)


def _credibility(
    *,
    verified: bool,
    followers: int,
    account_age_days: int,
    geo_confidence: float,
    urgency: float,
    contradiction: float = 0.0,
) -> float:
    cred = (
        0.25 * (1.0 if verified else 0.0)
        + 0.20 * min(1.0, math.log10(max(1, followers) + 1) / 6.0)
        + 0.15 * min(1.0, account_age_days / 365.0)
        + 0.20 * geo_confidence
        + 0.10 * urgency
        - 0.20 * contradiction
    )
    return max(0.0, min(1.0, cred))


def _geo_confidence(geo: dict | None) -> float:
    if not geo:
        return 0.0
    src = (geo.get("source") or "").lower()
    return {"gps": 1.0, "place_name": 0.6, "inferred": 0.3}.get(src, 0.0)


class SocialAgent(Agent):
    name = "social-agent"
    tier = 1

    def run(self, posts: Iterable[dict]) -> list[dict]:
        out: list[dict] = []
        for p in posts:
            artifact = self._process_post(p)
            self.emit("signals/social", artifact)
            out.append(artifact)
        return out

    def _process_post(self, post: dict) -> dict:
        text = post.get("text", "")
        lang = post.get("lang", "en")
        geo = post.get("geo")
        kws = _keyword_hits(text, lang)
        urgency = _urgency_score(text)
        geo_conf = _geo_confidence(geo)
        cred = _credibility(
            verified=post.get("user_verified", False),
            followers=int(post.get("user_followers", 0)),
            account_age_days=int(post.get("account_age_days", 0)),
            geo_confidence=geo_conf,
            urgency=urgency,
        )

        zone = None
        if geo and geo_conf >= 0.6:
            zone = zone_for(geo.get("lat"), geo.get("lon"))
        if not zone:
            zone = _zone_from_text(text)

        decision = "accept"
        if cred < 0.15:
            decision = "drop"
        elif cred < 0.35:
            decision = "unverified"

        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "signal_id": new_id("soc"),
            "source_post_id": post.get("id"),
            "lang": lang,
            "geo": {**(geo or {}), "confidence": geo_conf},
            "zone_match": zone,
            "keywords": kws,
            "urgency": urgency,
            "credibility": round(cred, 3),
            "media_attached": bool(post.get("media_urls")),
            "raw_text_hash": hashlib.sha256(text.encode()).hexdigest()[:16],
            "user_id_hash": _user_hash(post.get("user_id", "")),
            "decision": decision,
            "confidence": round(cred, 3),
            "envelope": {
                "agent": self.name,
                "tier": 1,
                "decision": decision,
                "confidence": round(cred, 3),
                "hypothesis": kws[0] if kws else None,
            },
        }


_ZONE_NAMES = (
    "G-10", "G-11", "G-13", "G-14", "G-6", "G-7", "G-8", "G-9",
    "F-6", "F-7", "F-7-katchi", "F-8", "F-10", "F-11",
    "I-8", "I-9", "I-10", "I-11", "E-7", "E-11",
    "Blue-Area", "Bara-Kahu", "Tarnol", "Rawal-Town",
    "Lok-Virsa", "Margalla-Town", "France-Colony", "Diplomatic-Enclave",
    "B-17", "Sector-D-12",
)


def _zone_from_text(text: str) -> str | None:
    low = text.lower()
    for z in _ZONE_NAMES:
        if z.lower() in low:
            return z
    # F-7 katchi variant
    if "katchi" in low and "f-7" in low:
        return "F-7-katchi"
    return None
