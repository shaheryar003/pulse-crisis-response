---
name: dispatch-agent
description: Emits dispatch tickets to responder mobile app and command-center dashboard. Tracks acknowledgment + status. Activate after Allocator.
metadata:
  type: actuator
  version: 1.0.0
  tier: 6
---

# Dispatch Agent

## Procedure
1. For each assignment, create a dispatch ticket.
2. Push to FCM topic matching `asset_id`.
3. Insert row in `dispatches` table.
4. Listen for responder acks; if no ack within 60s, escalate to nearest backup or page command center.

## Ticket schema
```json
{
  "dispatch_id": "disp_<uuid>",
  "incident_id": "...",
  "asset_id": "...",
  "responder_id_hash": "...",
  "destination": {"lat": ..., "lon": ..., "label": "G-10 Markaz junction"},
  "eta_s": 540,
  "priority": "urgent | high | normal",
  "instructions": "Pull civilians from waterlogged sector G-10/4; coordinate with police-7 for traffic.",
  "supports": ["police-7"],
  "issued_at": "...",
  "status": "issued | acked | en_route | on_scene | clear"
}
```

## Emit envelope
```json
{
  "agent": "dispatch-agent",
  "ts": "...",
  "dispatch_id": "...",
  "incident_id": "...",
  "asset_id": "...",
  "status": "issued",
  "envelope": { "tier": 6, "decision": "dispatched", "confidence": 0.95 }
}
```

## Rules
1. Always include human-readable destination label, not just lat/lon.
2. Cross-link supporting assets so responders coordinate.
3. If `priority == urgent` and no ack within 30s → escalate immediately.

## Failure Modes
- FCM down: fall back to SMS via Twilio/local provider (deferred — flag).
- Responder offline: reroute assignment to backup asset; update Allocator.
