"""
Report Management Service — citizen incident reports + authority review queue
Maps to "Report Management Service" and "Report Review Queue" boxes.

In production this writes to PostgreSQL (reports table) and Firebase
Storage (photos). This demo version uses an in-memory list so the
endpoints are fully testable without a database connection.
"""

from fastapi import APIRouter, HTTPException
from app.schemas import ReportIn, ReportOut
from typing import List

router = APIRouter(prefix="/reports", tags=["Report Management Service"])

_reports: List[dict] = []
_next_id = 1


@router.post("", response_model=ReportOut)
def submit_report(payload: ReportIn):
    """Citizen submits an incident (Accident / Pothole / Flooding / Debris)."""
    global _next_id
    record = {
        "id": _next_id,
        "category": payload.category,
        "lat": payload.lat,
        "lng": payload.lng,
        "description": payload.description,
        "photo_url": payload.photo_url,
        "reporter_id": payload.reporter_id,
        "status": "pending",
    }
    _reports.append(record)
    _next_id += 1
    return record


@router.get("", response_model=List[ReportOut])
def list_reports(status: str | None = None):
    """Authority portal: view all citizen reports, optionally filtered by status."""
    if status:
        return [r for r in _reports if r["status"] == status]
    return _reports


@router.post("/{report_id}/approve", response_model=ReportOut)
def approve_report(report_id: int):
    """Authority portal: approve a report -> feeds into hotspot recalculation."""
    for r in _reports:
        if r["id"] == report_id:
            r["status"] = "approved"
            return r
    raise HTTPException(status_code=404, detail="Report not found")


@router.post("/{report_id}/reject", response_model=ReportOut)
def reject_report(report_id: int):
    """Authority portal: reject a report."""
    for r in _reports:
        if r["id"] == report_id:
            r["status"] = "rejected"
            return r
    raise HTTPException(status_code=404, detail="Report not found")
