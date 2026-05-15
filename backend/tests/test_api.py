from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from backend.app.main import create_app


@pytest.fixture
def client(tmp_path: Path) -> TestClient:
    app = create_app(db_path=str(tmp_path / "pulse_test.db"))
    with TestClient(app) as c:
        yield c


def test_health(client: TestClient) -> None:
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_resources_seeded(client: TestClient) -> None:
    r = client.get("/resources")
    assert r.status_code == 200
    js = r.json()
    assert js["count"] >= 50
    assert any(a["type"] == "rescue" for a in js["assets"])


def test_openapi(client: TestClient) -> None:
    r = client.get("/openapi.json")
    assert r.status_code == 200
    spec = r.json()
    assert spec["openapi"].startswith("3.")
    paths = spec["paths"]
    for needed in ("/health", "/resources", "/incidents", "/signals/citizen", "/auth/otp/request", "/dispatch/queue"):
        assert needed in paths, f"missing path {needed}"


def test_auth_flow(client: TestClient) -> None:
    r1 = client.post("/auth/otp/request", json={"phone": "03001234567"})
    assert r1.status_code == 200
    r2 = client.post("/auth/otp/verify", json={"phone": "03001234567", "otp": "654321", "role": "citizen"})
    assert r2.status_code == 200
    body = r2.json()
    assert body["role"] == "citizen"
    assert body["token"]


def test_scenario_a_end_to_end(client: TestClient) -> None:
    sc_list = client.get("/scenarios").json()
    assert any(s["id"] == "A" for s in sc_list["scenarios"])
    r = client.post("/scenarios/A/run")
    assert r.status_code == 200, r.text
    js = r.json()
    assert js["scenario_id"] == "A"
    assert js["dispatches"] >= 1
    assert js["messages"] >= 1
    # Now /incidents should return persisted incidents
    inc = client.get("/incidents").json()
    assert inc["count"] >= 1


def test_citizen_report_persists(client: TestClient) -> None:
    payload = {
        "user_id": "demo",
        "category": "flood",
        "description": "water rising fast in G-10",
        "geo": {"lat": 33.696, "lon": 73.005, "accuracy_m": 10},
        "media": [],
        "ts": "2026-05-15T15:10:00Z",
        "user_trust": 0.5,
    }
    r = client.post("/signals/citizen", json=payload)
    assert r.status_code == 200
    sig = r.json()
    assert sig["agent"] == "citizen-report-agent"
    assert sig["zone"] == "G-10"


def test_dispatch_queue_lifecycle(client: TestClient) -> None:
    client.post("/scenarios/A/run")
    # Pick any dispatched asset
    inc = client.get("/incidents").json()
    incident_id = inc["incidents"][0]["incident_id"]
    audit = client.get(f"/incidents/{incident_id}").json()
    assert audit["incident"]["incident_id"] == incident_id
