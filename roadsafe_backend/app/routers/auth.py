"""
Authentication Service — maps to "Authentication Service" box.

In production this validates Firebase Auth ID tokens sent from the
Flutter app / Admin Web Portal. This demo version issues a mock token
so the flow can be shown end-to-end without a live Firebase project.
"""

from fastapi import APIRouter
from pydantic import BaseModel
import uuid

router = APIRouter(prefix="/auth", tags=["Authentication Service"])


class LoginRequest(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    token: str
    user_id: str
    role: str


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest):
    # Demo only: in production, verify against Firebase Auth instead.
    role = "authority" if payload.email.endswith("@roadsafe.gov.in") else "citizen"
    return LoginResponse(token=str(uuid.uuid4()), user_id=payload.email, role=role)
