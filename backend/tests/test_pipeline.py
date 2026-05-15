"""End-to-end pipeline test: scenario A produces a flood incident, dispatches,
and a recovery flip when an expert field report contradicts."""
from pathlib import Path

from backend.app.agents.base import ArtifactSink
from backend.app.agents.commander import Commander
from backend.app.services import loader


def test_scenario_a_flood(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    cmd = Commander(sink=sink)
    posts = [p for p in loader.social_posts() if p["id"] in {"s001", "s002", "s003", "s005", "s007"}]
    result = cmd.run_round(
        social_posts=posts,
        sensor_readings=loader.sensor_readings(),
        weather_overrides={"G-10": {"rain_mmhr": 47}},
        weather_mode="live",
    )
    assert result["incidents"], "expected at least one incident"
    types = [inc["classification"]["type"] for inc in result["incidents"]]
    assert "flood" in types
    flood_inc = next(inc for inc in result["incidents"] if inc["classification"]["type"] == "flood")
    assert flood_inc["classification"]["zone"] == "G-10"
    assert result["dispatches"], "should have at least one dispatch"
    assert result["messages"], "should have stakeholder messages"


def test_recovery_flips_to_water_main(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    cmd = Commander(sink=sink)
    posts = [p for p in loader.social_posts() if p["id"] in {"s001", "s002", "s003", "s007"}]
    # Expert engineer field report contradicting flood hypothesis
    field_reports = [{
        "report_id": "fr_eng1",
        "user_id": "engineer_zaid",
        "user_trust": 0.92,
        "category": "water_main_burst",
        "description": "Water gushing from one fixed point at G-10/4, not rain — definitely a burst main.",
        "geo": {"lat": 33.696, "lon": 73.005, "accuracy_m": 5},
        "media": [{"type": "photo", "url": "main.jpg"}],
        "ts": "2026-05-15T15:14:00Z",
    }]
    result = cmd.run_round(
        social_posts=posts,
        sensor_readings=loader.sensor_readings(),
        weather_overrides={"G-10": {"rain_mmhr": 47}},
        weather_mode="live",
        recovery_field_reports=field_reports,
    )
    assert result["recall"], "recall artifact expected after expert correction"
    audit = result["recall"][0]["audit"]
    assert audit["original"]["type"] == "flood"
    assert audit["new"]["type"] == "water_main_burst"
    assert audit["user_impact"]["responders_recalled"] >= 1
