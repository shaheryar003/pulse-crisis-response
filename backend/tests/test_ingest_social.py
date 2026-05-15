from pathlib import Path

from backend.app.agents.base import ArtifactSink
from backend.app.agents.ingest.social import SocialAgent, _credibility


def test_credibility_floor_and_ceiling():
    low = _credibility(verified=False, followers=0, account_age_days=0, geo_confidence=0.0, urgency=0.0)
    high = _credibility(verified=True, followers=100000, account_age_days=3000, geo_confidence=1.0, urgency=1.0)
    assert 0.0 <= low <= 0.05
    assert high >= 0.85


def test_social_agent_classifies(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    a = SocialAgent(sink)
    posts = [
        {"id": "s001", "ts": "2026-05-15T15:02:00Z", "user_id": "u1", "user_followers": 230, "user_verified": False, "account_age_days": 640,
         "geo": {"lat": 33.696, "lon": 73.005, "source": "gps"}, "lang": "en", "text": "flood in G-10 streets underwater urgent help"},
        {"id": "s002", "ts": "2026-05-15T15:03:00Z", "user_id": "u2", "user_followers": 12, "user_verified": False, "account_age_days": 4,
         "geo": {"lat": 33.696, "lon": 73.005, "source": "inferred"}, "lang": "en", "text": "FLOOD G10 SHARE NOW"},
    ]
    out = a.run(posts)
    assert len(out) == 2
    decisions = [o["decision"] for o in out]
    assert "accept" in decisions or "unverified" in decisions
    # bot-like post should be unverified or dropped
    bot = [o for o in out if o["source_post_id"] == "s002"][0]
    assert bot["decision"] in ("unverified", "drop")
    real = [o for o in out if o["source_post_id"] == "s001"][0]
    assert real["zone_match"] == "G-10"
    assert "flood" in real["keywords"]
