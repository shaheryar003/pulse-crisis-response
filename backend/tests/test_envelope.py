from pathlib import Path

from backend.app.agents.base import Agent, ArtifactSink, Envelope, iso_now, new_id


def test_envelope_to_dict():
    env = Envelope(agent="x", tier=1, run_id="r1", ts=iso_now(), decision="accept", confidence=0.5)
    d = env.to_dict()
    assert d["agent"] == "x"
    assert d["tier"] == 1
    assert d["decision"] == "accept"
    assert "evidence" in d


def test_sink_writes(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    payload = {"id": "abc", "run_id": "run_x", "value": 1}
    path = sink.write("test", payload)
    assert Path(path).exists()
    assert sink.drain() and sink.in_memory == []
