from pathlib import Path

from backend.app.agents.base import ArtifactSink
from backend.app.agents.fusion import FusionAgent


def _social(sig_id, zone, cred, geo, user="u_a"):
    return {
        "agent": "social-agent",
        "signal_id": sig_id,
        "zone_match": zone,
        "credibility": cred,
        "confidence": cred,
        "decision": "accept",
        "geo": geo,
        "envelope": {"hypothesis": "flood"},
        "keywords": ["flood"],
        "user_id_hash": user,
        "ts": "2026-05-15T15:00:00Z",
    }


def test_fusion_clusters_g10_signals(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    f = FusionAgent(sink)
    sigs = [
        _social("s1", "G-10", 0.7, {"lat": 33.696, "lon": 73.005}),
        _social("s2", "G-10", 0.65, {"lat": 33.697, "lon": 73.006}, user="u_b"),
        _social("s3", "G-10", 0.8, {"lat": 33.694, "lon": 73.004}, user="u_c"),
    ]
    out = f.run(sigs)
    assert len(out) == 1
    cand = out[0]
    assert cand["zone"] == "G-10"
    assert cand["hypothesis_seed"] == "flood"
    assert len(cand["signal_ids"]) == 3


def test_fusion_same_user_no_multi_source(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    f = FusionAgent(sink)
    sigs = [_social(f"s{i}", "G-10", 0.6, {"lat": 33.696, "lon": 73.005}, user="u_same") for i in range(3)]
    out = f.run(sigs)
    assert len(out) == 1
    assert out[0]["source_types"] == ["social"]
    # single source + low cred => weak_candidate
    assert out[0]["decision"] in ("weak_candidate", "candidate_formed")
