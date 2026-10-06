"""
RoadSafe Backend — FastAPI + Python
Entry point wiring together all services shown in the architecture diagram:
  - Authentication Service
  - Report Management Service (+ Report Review Queue)
  - Geo Query Service (Nearby Hotspots)
  - Notification Service (FCM)
  - Hotspot Detection Engine (rule-based Risk Score Calculation)

Run with:  uvicorn app.main:app --reload
Docs at:   http://127.0.0.1:8000/docs
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, reports, geo_query, hotspot_engine, notifications

app = FastAPI(
    title="RoadSafe API",
    description="Backend for the RoadSafe road-safety mobile app",
    version="1.0.0",
)

# Allow the Flutter app (mobile) and Admin Web Portal to call this API
# during development. Restrict allow_origins in production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(reports.router)
app.include_router(geo_query.router)
app.include_router(hotspot_engine.router)
app.include_router(notifications.router)


@app.get("/")
def root():
    return {"status": "ok", "service": "RoadSafe API", "docs": "/docs"}
