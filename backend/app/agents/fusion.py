"""FusionAgent (Tier 2) — spatiotemporal clustering of Tier-1 signals."""
from __future__ import annotations

import math
from collections import Counter, defaultdict
from datetime import datetime
from typing import Iterable

from .base import Agent, new_id
from ..services.geo import haversine_km, zone_for


SIGNAL_TYPE_TO_SOURCE = {
    "social-agent": "social",
    "weather-agent": "weather",
    "traffic-agent": "traffic",
    "sensor-agent": "sensor",
    "citizen-report-agent": "citizen",
    "historical-agent": "historical",
}

KEYWORD_TO_HYPOTHESIS = {
    "flood": "flood",
    "fire": "fire",
    "heatwave": "heatwave",
    "heat_critical": "heatwave",
    "heat_watch": "heatwave",
    "accident": "accident",
    "power_outage": "power_outage",
    "outage_risk": "power_outage",
    "water_main_burst": "water_main_burst",
    "gas_leak": "gas_leak",
    "public_disorder": "public_disorder",
    "flood_risk": "flood",
    "flood_watch": "flood",
    "urban_flood": "flood",
    "severe_congestion": "accident",
    "congestion_spike": "accident",
    "air_hazard": "air_hazard",
    "collapse_risk": "infrastructure_failure",
    "infrastructure": "infrastructure_failure",
    "medical": "medical",
}


def _signal_geo(sig: dict) -> tuple[float, float] | None:
    g = sig.get("geo") or {}
    if isinstance(g, dict) and "lat" in g and g.get("lat") is not None:
        return float(g["lat"]), float(g["lon"])
    return None


def _signal_zone(sig: dict) -> str | None:
    return sig.get("zone") or sig.get("zone_match")


def _signal_hypothesis(sig: dict) -> str | None:
    env = sig.get("envelope") or {}
    hyp = env.get("hypothesis")
    if hyp and hyp in KEYWORD_TO_HYPOTHESIS:
        return KEYWORD_TO_HYPOTHESIS[hyp]
    # keywords list (social)
    for k in sig.get("keywords") or []:
        if k in KEYWORD_TO_HYPOTHESIS:
            return KEYWORD_TO_HYPOTHESIS[k]
    if sig.get("trigger") in KEYWORD_TO_HYPOTHESIS:
        return KEYWORD_TO_HYPOTHESIS[sig["trigger"]]
    return None


class FusionAgent(Agent):
    name = "fusion-agent"
    tier = 2

    def __init__(self, *args, eps_km: float = 0.6, **kwargs):
        super().__init__(*args, **kwargs)
        self.eps_km = eps_km

    def run(self, signals: Iterable[dict]) -> list[dict]:
        signals = [s for s in signals if s.get("decision") != "drop"]
        # Bucket primarily by zone (cheap stable key), then refine by geo distance.
        zone_buckets: dict[str, list[dict]] = defaultdict(list)
        for s in signals:
            z = _signal_zone(s)
            if not z:
                continue
            zone_buckets[z].append(s)

        candidates: list[dict] = []
        for zone, bucket in zone_buckets.items():
            sub_clusters = self._refine(bucket)
            for cluster in sub_clusters:
                cand = self._build_candidate(zone, cluster)
                if cand:
                    self.emit("incidents/candidate", cand)
                    candidates.append(cand)
        return candidates

    def _refine(self, signals: list[dict]) -> list[list[dict]]:
        # Simple agglomerative on geo where available; else single zone-wide cluster.
        with_geo = [s for s in signals if _signal_geo(s)]
        without_geo = [s for s in signals if not _signal_geo(s)]
        clusters: list[list[dict]] = []
        for s in with_geo:
            placed = False
            for c in clusters:
                ref = c[0]
                rg, sg = _signal_geo(ref), _signal_geo(s)
                if rg is None or sg is None:
                    continue
                if haversine_km(rg[0], rg[1], sg[0], sg[1]) <= self.eps_km:
                    c.append(s)
                    placed = True
                    break
            if not placed:
                clusters.append([s])
        if without_geo:
            if clusters:
                clusters[0].extend(without_geo)
            else:
                clusters.append(list(without_geo))
        return clusters

    def _build_candidate(self, zone: str, cluster: list[dict]) -> dict | None:
        sources = {SIGNAL_TYPE_TO_SOURCE.get(s.get("agent"), s.get("agent")) for s in cluster}
        # Dedup social: same user
        social = [s for s in cluster if s.get("agent") == "social-agent"]
        unique_social_users = {s.get("user_id_hash") for s in social}
        if len(social) >= 2 and len(unique_social_users) == 1 and len(sources) == 1:
            # Same user spamming; not multi-source
            sources = {"social"}
        diversity = 1.0 - (1.0 / max(1, len(sources)))
        avg_cred = sum(s.get("credibility", s.get("confidence", 0.5)) for s in cluster) / len(cluster)

        # Hypothesis voting
        hyps = [_signal_hypothesis(s) for s in cluster]
        hyps = [h for h in hyps if h]
        if not hyps:
            return None
        ranked = Counter(hyps).most_common()
        hypothesis_seed = ranked[0][0]

        # Determine centroid
        geos = [_signal_geo(s) for s in cluster if _signal_geo(s)]
        if geos:
            lat = sum(g[0] for g in geos) / len(geos)
            lon = sum(g[1] for g in geos) / len(geos)
        else:
            lat = lon = None

        ts_list = sorted(s.get("ts") or "" for s in cluster)
        ts_first = ts_list[0] if ts_list else ""
        ts_last = ts_list[-1] if ts_list else ""

        weak = len(sources) == 1 and avg_cred < 0.5
        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "candidate_id": new_id("cand"),
            "zone": zone,
            "centroid": {"lat": lat, "lon": lon},
            "signal_ids": [s.get("signal_id") for s in cluster],
            "source_types": sorted(sources),
            "diversity_score": round(diversity, 3),
            "avg_credibility": round(avg_cred, 3),
            "hypothesis_seed": hypothesis_seed,
            "ts_first_signal": ts_first,
            "ts_last_signal": ts_last,
            "decision": "weak_candidate" if weak else "candidate_formed",
            "confidence": round(avg_cred * (0.6 + 0.4 * diversity), 3),
            "envelope": {
                "agent": self.name,
                "tier": 2,
                "decision": "weak_candidate" if weak else "candidate_formed",
                "confidence": round(avg_cred * (0.6 + 0.4 * diversity), 3),
                "hypothesis": hypothesis_seed,
            },
        }
