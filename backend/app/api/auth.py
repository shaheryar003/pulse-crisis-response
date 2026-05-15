"""Mock phone-OTP auth. Stores OTP in memory for demo determinism."""
from __future__ import annotations

import hashlib
import hmac
import os
import time

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/auth", tags=["auth"])

_otp_store: dict[str, tuple[str, float]] = {}  # phone -> (otp, expiry_epoch)
_demo_otp = os.getenv("PULSE_DEMO_OTP", "654321")


class OtpRequest(BaseModel):
    phone: str = Field(min_length=8, max_length=20)


class OtpVerify(BaseModel):
    phone: str
    otp: str
    role: str = "citizen"


@router.post("/otp/request")
def request_otp(req: OtpRequest) -> dict:
    _otp_store[req.phone] = (_demo_otp, time.time() + 300)
    # In real deployment, this would send via SMS provider.
    return {"sent": True, "channel": "sms_mock", "expires_in": 300, "demo_hint": "use 654321 in demo"}


@router.post("/otp/verify")
def verify_otp(req: OtpVerify) -> dict:
    rec = _otp_store.get(req.phone)
    if not rec or rec[1] < time.time() or not hmac.compare_digest(rec[0], req.otp):
        raise HTTPException(status_code=401, detail="invalid_or_expired_otp")
    if req.role not in ("citizen", "responder", "command"):
        raise HTTPException(status_code=400, detail="bad_role")
    user_id = "u_" + hashlib.sha256(req.phone.encode()).hexdigest()[:10]
    # Demo: synthetic JWT-like token (NOT for production). Mobile uses as bearer.
    token = hashlib.sha256(f"{user_id}|{req.role}|{int(time.time())}".encode()).hexdigest()
    return {"token": token, "user_id": user_id, "role": req.role}
