"""ResourceAllocator (Tier 5) — Hungarian bipartite matching."""
from __future__ import annotations

import math
from typing import Iterable

import numpy as np
from scipy.optimize import linear_sum_assignment

from .base import Agent
from ..services.geo import zone_properties, haversine_km, eta_seconds
from ..services.loader import depot_geo, resources as load_resources


REQUIRED_BY_TYPE: dict[str, list[tuple[str, int]]] = {
    # (capability, count)
    "flood": [("rescue", 2), ("police_traffic", 2), ("ambulance", 1)],
    "heatwave": [("ambulance", 2), ("mobile_clinic", 1), ("water_tanker", 1)],
    "fire": [("fire_unit", 2), ("ambulance", 1), ("police_traffic", 1)],
    "accident": [("ambulance", 1), ("police_traffic", 1)],
    "power_outage": [("utility_crew", 1), ("generator", 1)],
    "water_main_burst": [("utility_crew", 1), ("police_traffic", 1)],
    "infrastructure_failure": [("rescue", 1), ("utility_crew", 1), ("police_traffic", 1)],
    "gas_leak": [("fire_unit", 1), ("utility_crew", 1)],
    "public_disorder": [("police_traffic", 3)],
    "disease_cluster": [("mobile_clinic", 2), ("ambulance", 1)],
    "other": [("police_traffic", 1)],
}


class ResourceAllocator(Agent):
    name = "resource-allocator"
    tier = 5

    def run(self, *, ranking: list[dict], assets: list[dict] | None = None) -> dict:
        fleet = list(assets) if assets is not None else list(load_resources())
        # Build per-need rows: each incident expands to one row per required capability slot.
        rows: list[dict] = []
        for r in ranking:
            inc_type = r["type"]
            for cap, n in REQUIRED_BY_TYPE.get(inc_type, [("police_traffic", 1)]):
                for slot_idx in range(n):
                    rows.append({
                        "incident_id": r["incident_id"],
                        "zone": r["zone"],
                        "required": cap,
                        "priority": r["priority"],
                        "slot": slot_idx,
                    })

        feasible_assets = [a for a in fleet if a.get("status") == "available"]
        if not rows or not feasible_assets:
            artifact = self._artifact([], [], cost=0.0)
            self.emit("alloc", artifact)
            return artifact

        # Build cost matrix
        # Pad columns so square matrix isn't required: use rectangular Hungarian (scipy supports).
        cost = np.full((len(rows), len(feasible_assets)), 1e6, dtype=float)
        zone_centroids: dict[str, tuple[float, float]] = {}
        for i, row in enumerate(rows):
            zp = zone_properties(row["zone"])
            # zone centroid approximated by geo of facilities; fall back to (0,0)
            cz = self._zone_centroid(row["zone"])
            for j, a in enumerate(feasible_assets):
                if row["required"] not in a.get("capabilities", []) and row["required"] != a.get("type"):
                    continue
                depot = depot_geo(a.get("depot", "")) or {"lat": 33.7, "lon": 73.05}
                travel = eta_seconds(depot["lat"], depot["lon"], cz[0], cz[1])
                cap_overlap = 1.0 if row["required"] in a.get("capabilities", []) else 0.0
                fatigue = 0.0  # placeholder; could read from asset state
                c = (
                    travel
                    + 1.0 * (1 - cap_overlap) * 600
                    - 1.0 * row["priority"] * 300
                    + 0.3 * fatigue * 600
                )
                cost[i, j] = max(0.0, c)

        # Drop unreachable rows for fairer allocation
        reachable_rows = [i for i in range(len(rows)) if cost[i, :].min() < 1e6]
        if not reachable_rows:
            artifact = self._artifact([], [], cost=0.0, unmet=rows)
            self.emit("alloc", artifact)
            return artifact

        sub_cost = cost[reachable_rows, :]
        row_ind, col_ind = linear_sum_assignment(sub_cost)
        assignments: dict[str, list[dict]] = {}
        used_assets: set[str] = set()
        for ri, ci in zip(row_ind, col_ind):
            actual_row = reachable_rows[ri]
            row = rows[actual_row]
            a = feasible_assets[ci]
            if a["asset_id"] in used_assets:
                continue
            if sub_cost[ri, ci] >= 1e6:
                continue
            used_assets.add(a["asset_id"])
            depot = depot_geo(a.get("depot", "")) or {"lat": 33.7, "lon": 73.05}
            cz = self._zone_centroid(row["zone"])
            eta_s = eta_seconds(depot["lat"], depot["lon"], cz[0], cz[1])
            assignments.setdefault(row["incident_id"], []).append({
                "asset_id": a["asset_id"],
                "type": a["type"],
                "from": a.get("depot"),
                "eta_s": eta_s,
                "required": row["required"],
            })

        per_incident = []
        unmet_total = []
        for r in ranking:
            iid = r["incident_id"]
            assigned = assignments.get(iid, [])
            required_set = REQUIRED_BY_TYPE.get(r["type"], [])
            need_total = sum(n for _, n in required_set)
            got_capabilities = [x["required"] for x in assigned]
            coverage = (
                sum(min(got_capabilities.count(cap), n) for cap, n in required_set) / need_total
                if need_total else 1.0
            )
            unmet = []
            for cap, n in required_set:
                got = got_capabilities.count(cap)
                if got < n:
                    unmet.append({"capability": cap, "shortfall": n - got})
            unmet_total.extend(unmet)
            per_incident.append({
                "incident_id": iid,
                "zone": r["zone"],
                "assigned_assets": assigned,
                "capability_coverage": round(coverage, 3),
                "unmet": unmet,
            })

        alternatives = self._compute_alternative(rows, feasible_assets, cost, assignments)

        artifact = self._artifact(per_incident, alternatives, cost=float(sub_cost[row_ind, col_ind].sum()), unmet=unmet_total)
        self.emit("alloc", artifact)
        return artifact

    def _zone_centroid(self, zone_id: str) -> tuple[float, float]:
        from ..services.geo import zone_centroid
        cz = zone_centroid(zone_id)
        return cz if cz else (33.7, 73.05)

    def _compute_alternative(self, rows, assets, cost, current) -> list[str]:
        # The alternative: take the highest-priority incident's first asset and pick second-best.
        if not rows:
            return []
        out: list[str] = []
        used_assets = {a["asset_id"] for asg in current.values() for a in asg}
        first = rows[0]
        candidates = []
        for j, a in enumerate(assets):
            if a["asset_id"] in used_assets:
                continue
            c = cost[0, j]
            if c < 1e6:
                candidates.append((c, a["asset_id"]))
        candidates.sort()
        if candidates:
            out.append(
                f"Alternative for {first['incident_id']}: use {candidates[0][1]} (cost {candidates[0][0]:.0f}s) instead of best — "
                f"would save unused-asset slack but increase travel by ~{int(candidates[0][0])}s."
            )
        return out

    def _artifact(self, assignments: list[dict], alternatives: list[str], *, cost: float, unmet: list | None = None) -> dict:
        return {
            "agent": self.name,
            "tier": self.tier,
            "run_id": self.run_id,
            "assignments": assignments,
            "total_cost": round(cost, 2),
            "alternatives_considered": alternatives,
            "unmet": unmet or [],
            "decision": "allocated",
            "confidence": 0.92 if assignments else 0.4,
            "envelope": {
                "agent": self.name,
                "tier": 5,
                "decision": "allocated",
                "confidence": 0.92 if assignments else 0.4,
                "hypothesis": None,
            },
        }
