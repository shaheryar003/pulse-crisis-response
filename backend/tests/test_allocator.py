from pathlib import Path

from backend.app.agents.base import ArtifactSink
from backend.app.agents.allocator import ResourceAllocator


def test_allocator_assigns_for_flood(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    alloc = ResourceAllocator(sink)
    ranking = [
        {"incident_id": "inc_a", "zone": "G-10", "type": "flood", "priority": 0.8, "rank": 1,
         "severity": 4, "pop_p50": 28000, "rationale": "...", "recommended_resource_share": 0.6,
         "floor_assignment": True},
    ]
    out = alloc.run(ranking=ranking)
    assert out["assignments"], "should assign at least one asset"
    asgn = out["assignments"][0]
    caps = [a["required"] for a in asgn["assigned_assets"]]
    # Floods require rescue + police + ambulance
    assert "rescue" in caps
    assert "police_traffic" in caps
    assert asgn["capability_coverage"] >= 0.6


def test_allocator_multi_incident_tradeoff(tmp_path: Path):
    sink = ArtifactSink(root=tmp_path)
    alloc = ResourceAllocator(sink)
    ranking = [
        {"incident_id": "inc_a", "zone": "G-10", "type": "flood", "priority": 0.82, "rank": 1,
         "severity": 4, "pop_p50": 28000, "rationale": "", "recommended_resource_share": 0.62, "floor_assignment": True},
        {"incident_id": "inc_b", "zone": "F-7-katchi", "type": "heatwave", "priority": 0.66, "rank": 2,
         "severity": 3, "pop_p50": 8500, "rationale": "", "recommended_resource_share": 0.38, "floor_assignment": True},
    ]
    out = alloc.run(ranking=ranking)
    ids = {a["incident_id"] for a in out["assignments"]}
    assert "inc_a" in ids and "inc_b" in ids
    # Allocator should have produced an alternatives-considered string
    assert len(out["alternatives_considered"]) >= 1
