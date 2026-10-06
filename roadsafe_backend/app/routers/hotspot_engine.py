"""
Hotspot Detection Engine — DBSCAN clustering over the full dataset.
Maps to the "AI / ML Hotspot Engine" box end-to-end.

GET  /risk/clusters         — all DBSCAN clusters found across the dataset
GET  /risk/clusters/top     — top N highest-risk clusters (for map rendering)
POST /risk/nearest          — find the nearest cluster to a given lat/lng
"""

import os
from fastapi import APIRouter
from app.schemas import HotspotClusterOut, NearestHotspotRequest
from app.hotspot_clustering import DBSCANHotspotEngine

router = APIRouter(prefix="/risk", tags=["Hotspot Detection Engine (DBSCAN)"])

CSV_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "indian_roads_dataset.csv")

# DBSCAN runs once at startup across the full 20,000-record dataset.
_engine = DBSCANHotspotEngine(CSV_PATH, eps_km=1.5, min_samples=10)


@router.get("/clusters", response_model=list[HotspotClusterOut])
def get_all_clusters():
    return [c.__dict__ for c in _engine.all_hotspots()]


@router.get("/clusters/top", response_model=list[HotspotClusterOut])
def get_top_clusters(n: int = 40):
    return [c.__dict__ for c in _engine.top_hotspots(n)]


@router.post("/nearest")
def nearest_cluster(payload: NearestHotspotRequest):
    cluster, distance_m = _engine.nearest_hotspot(payload.lat, payload.lng)
    if cluster is None:
        return {"found": False}
    return {
        "found": True,
        "distance_m": round(distance_m, 1),
        "cluster": cluster.__dict__,
    }