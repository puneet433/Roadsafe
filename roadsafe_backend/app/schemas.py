"""Shared request/response models used across routers."""

from pydantic import BaseModel, Field
from typing import Optional


class ReportIn(BaseModel):
    category: str = Field(..., description="Accident | Pothole | Flooding | Debris")
    lat: float
    lng: float
    description: Optional[str] = None
    photo_url: Optional[str] = None
    reporter_id: Optional[str] = None


class ReportOut(BaseModel):
    id: int
    category: str
    lat: float
    lng: float
    status: str  # 'pending' | 'approved' | 'rejected'

class HotspotClusterOut(BaseModel):
    cluster_id: int
    city: str
    center_lat: float
    center_lng: float
    radius_m: int
    incident_count: int
    avg_risk_score: float
    fatal_rate_pct: float
    risk_level: str


class NearestHotspotRequest(BaseModel):
    lat: float
    lng: float



class HotspotOut(BaseModel):
    name: str
    lat: float
    lng: float
    risk: str
    radius_m: int
    historical_incidents: int
