"""VerificationAgent (Tier 2) — hypothesis ranking + recovery triggering."""
from __future__ import annotations

from collections import Counter

from .base import Agent, new_id
from .fusion import _signal_hypothesis  # reuse heuristic mapping


HYP_EVIDENCE_WEIGHT = {
    "weather-agent": {"flood": +0.35, "heatwave": +0.30, "fire": -0.05, "water_main_burst": -0.10},
    "sensor-agent": {"flood": +0.30, "fire": +0.30, "heatwave": +0.30, "water_main_burst": +0.10, "power_outage": +0.30, "infrastructure_failure": +0.30, "air_hazard": +0.30},
    "social-agent": {"flood": +0.20, "fire": +0.20, "heatwave": +0.20, "water_main_burst": +0.20, "accident": +0.20, "public_disorder": +0.25},
    "traffic-agent": {"flood": +0.10, "accident": +0.25, "public_disorder": +0.15},
    "citizen-report-agent": {"flood": +0.30, "water_main_burst": +0.40, "fire": +0.30, "accident": +0.30, "infrastructure_failure": +0.40},
}


class VerificationAgent(Agent):
    name = "verification-agent"
    tier = 2

    def run(self, *, candidate: dict, contributing_signals: list[dict], prior_classification: dict | None = None) -> dict:
        hypotheses = self._rank_hypotheses(candidate, contributing_signals)
        contradictions = self._contradictions(contributing_signals)
        misinfo = self._misinfo_flags(contributing_signals)
        recovery, flip_to = self._recovery_check(prior_classification, hypotheses, contributing_signals)

        top, second = (hypotheses[0], hypotheses[1] if len(hypotheses) > 1 else None)
        ambiguous = bool(second and abs(top["score"] - second["score"]) < 0.15)
        decision = "flip" if recovery else ("ambiguous" if ambiguous else "verified")

        artifact = {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "candidate_id": candidate.get("candidate_id"),
            "hypotheses": hypotheses,
            "ambiguity": ambiguous,
            "contradictions": contradictions,
            "misinformation_flags": misinfo,
            "recovery_triggered": recovery,
            "flip_to": flip_to,
            "decision": decision,
            "confidence": round(top["score"], 3),
            "envelope": {
                "agent": self.name,
                "tier": 2,
                "decision": decision,
                "confidence": round(top["score"], 3),
                "hypothesis": top["label"],
            },
        }
        self.emit("verify", artifact)
        return artifact

    def _rank_hypotheses(self, candidate: dict, signals: list[dict]) -> list[dict]:
        scores: dict[str, float] = {}
        evidence_rows: dict[str, list[dict]] = {}
        seed = candidate.get("hypothesis_seed")
        if seed:
            scores[seed] = 0.0
            evidence_rows[seed] = []

        for s in signals:
            hyp = _signal_hypothesis(s)
            if not hyp:
                continue
            base = HYP_EVIDENCE_WEIGHT.get(s.get("agent"), {}).get(hyp, 0.15)
            cred = s.get("credibility", s.get("confidence", 0.5))
            weighted = base * float(cred)
            scores[hyp] = scores.get(hyp, 0.0) + weighted
            evidence_rows.setdefault(hyp, []).append({
                "agent": s.get("agent"),
                "signal_id": s.get("signal_id"),
                "delta": round(weighted, 3),
                "credibility": cred,
            })

        # Expert correction signal flips the top hypothesis if applicable.
        # Expert signals are authoritative: they bump their target hypothesis hard
        # and dampen all competitors (modeling "ground truth from the field").
        for s in signals:
            if s.get("envelope", {}).get("decision") == "expert_correction":
                hyp = _signal_hypothesis(s) or s.get("category")
                if hyp:
                    bump = 1.5 * float(s.get("credibility", 0.85))
                    scores[hyp] = scores.get(hyp, 0.0) + bump
                    evidence_rows.setdefault(hyp, []).append({
                        "agent": s.get("agent"),
                        "expert_correction": True,
                        "delta": round(bump, 3),
                    })
                    for other in list(scores.keys()):
                        if other != hyp:
                            scores[other] *= 0.35

        ranked = [
            {"label": k, "score": max(0.0, min(1.0, v)), "evidence": evidence_rows.get(k, [])}
            for k, v in sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
        ]
        if not ranked:
            ranked = [{"label": seed or "unknown", "score": 0.3, "evidence": []}]
        return ranked

    def _contradictions(self, signals: list[dict]) -> list[dict]:
        out = []
        rain_sig = next((s for s in signals if s.get("agent") == "weather-agent" and any(t in (s.get("triggers") or []) for t in ("flood_risk", "flood_watch"))), None)
        water_main_sig = next((s for s in signals if (s.get("envelope", {}).get("hypothesis") == "water_main_burst")), None)
        if water_main_sig and not rain_sig:
            out.append({"kind": "social_flood_without_weather", "explanation": "flood claimed but no rainfall signal — possible water main burst"})
        if water_main_sig and rain_sig and rain_sig.get("vars", {}).get("rain_mmhr", 0) < 5:
            out.append({"kind": "low_rainfall_with_flood_claim", "explanation": "rainfall too low for claimed flood severity"})
        return out

    def _misinfo_flags(self, signals: list[dict]) -> list[str]:
        flags = []
        socials = [s for s in signals if s.get("agent") == "social-agent"]
        if not socials:
            return flags
        new_account_share = sum(1 for s in socials if s.get("envelope", {}).get("decision") == "unverified") / len(socials)
        if new_account_share > 0.4:
            flags.append("possible_misinformation:new_account_velocity")
        return flags

    def _recovery_check(self, prior: dict | None, hypotheses: list[dict], signals: list[dict]) -> tuple[bool, str | None]:
        if not prior:
            return False, None
        top = hypotheses[0]["label"] if hypotheses else None
        # Recovery if expert correction landed AND it changes top hypothesis.
        expert = [s for s in signals if s.get("envelope", {}).get("decision") == "expert_correction"]
        if expert and top != prior.get("type"):
            return True, top
        # Or if new high-cred signal disagrees with prior.
        for s in signals:
            if s.get("credibility", 0) >= 0.85:
                h = _signal_hypothesis(s)
                if h and h != prior.get("type"):
                    return True, h
        return False, None
