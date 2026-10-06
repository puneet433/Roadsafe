"""
Geo Query Service — GET /hotspots/all, /hotspots/nearby
Now backed entirely by the DBSCAN clustering engine — every hotspot
returned here is a real cluster mined from the full dataset, not a
hand-picked point.
"""

import os
from fastapi import APIRouter, Query
from app.schemas import HotspotOut
from app.hotspot_clustering import DBSCANHotspotEngine
from typing import List

router = APIRouter(prefix="/hotspots", tags=["Geo Query Service"])

CSV_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "indian_roads_dataset.csv")

# Reuses the same DBSCAN engine instance concept — in a larger app this
# would be a shared singleton; kept simple and explicit here.
_engine = DBSCANHotspotEngine(CSV_PATH, eps_km=1.5, min_samples=10)


@router.get("/all", response_model=List[HotspotOut])
def get_all_hotspots(top: int = 40):
    """Top N highest-risk DBSCAN clusters, used to render the map heatmap."""
    clusters = _engine.top_hotspots(top)
    return [
        {
            "name": f"{c.city} Cluster #{c.cluster_id}",
            "lat": c.center_lat,
            "lng": c.center_lng,
            "risk": c.risk_level,
            "radius_m": c.radius_m,
            "historical_incidents": c.incident_count,
        }
        for c in clusters
    ]


@router.get("/nearby", response_model=List[HotspotOut])
def get_nearby_hotspots(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_m: int = Query(500, description="Search radius in meters"),
):
    clusters = _engine.nearby_hotspots(lat, lng, radius_m)
    return [
        {
            "name": f"{c.city} Cluster #{c.cluster_id}",
            "lat": c.center_lat,
            "lng": c.center_lng,
            "risk": c.risk_level,
            "radius_m": c.radius_m,
            "historical_incidents": c.incident_count,
        }
        for c in clusters
    ]