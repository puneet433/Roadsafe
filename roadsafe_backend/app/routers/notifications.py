"""
Notification Service — maps to "Notification Service (FCM)" box.

In production this calls Firebase Cloud Messaging to push alert
notifications, incident status updates, and system announcements to
driver devices. This demo version logs the payload instead of a live
FCM call, so the endpoint is testable without Firebase credentials.
"""

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/notify", tags=["Notification Service"])


class PushRequest(BaseModel):
    device_token: str
    title: str
    body: str


@router.post("/push")
def send_push(payload: PushRequest):
    # In production: firebase_admin.messaging.send(...)
    print(f"[FCM MOCK] -> {payload.device_token}: {payload.title} — {payload.body}")
    return {"status": "sent", "title": payload.title}
