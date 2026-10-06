"""
RoadSafe — DBSCAN Hotspot Clustering Engine (per-city)
Maps to the "AI / ML Hotspot Engine" box:
Historical Accident Data -> Data Preprocessing -> DBSCAN Clustering ->
Risk Score Calculation -> Hotspot Generation (Center, Radius, Risk Level).

DBSCAN now runs SEPARATELY per city, guaranteeing:
  - records from different cities can never be merged into one cluster
  - every city gets its own independently-computed hotspot(s) - one city
    may produce 1 broad cluster, another may produce 60+ tight clusters,
    depending on how its own accidents are actually distributed
All 20,000 records across all 8 cities are analyzed; nothing is sampled.
"""

import pandas as pd
import numpy as np
from sklearn.cluster import DBSCAN
from math import radians, sin, cos, sqrt, atan2
from dataclasses import dataclass, field
from typing import List


@dataclass
class Hotspot:
    cluster_id: int
    city: str
    center_lat: float
    center_lng: float
    radius_m: int
    incident_count: int
    avg_risk_score: float
    fatal_rate_pct: float
    risk_level: str  # 'high' | 'medium' | 'low'


def _haversine_m(lat1, lng1, lat2, lng2) -> float:
    R = 6371000
    p1, p2 = radians(lat1), radians(lat2)
    dphi = radians(lat2 - lat1)
    dlambda = radians(lng2 - lng1)
    a = sin(dphi / 2) ** 2 + cos(p1) * cos(p2) * sin(dlambda / 2) ** 2
    return 2 * R * atan2(sqrt(a), sqrt(1 - a))


class DBSCANHotspotEngine:
    def __init__(self, csv_path: str, eps_km: float = 1.5, min_samples: int = 10):
        self.eps_km = eps_km
        self.min_samples = min_samples
        self.df = self._load_and_clean(csv_path)
        self.clusters: List[Hotspot] = []
        self._run_dbscan_per_city()

    def _load_and_clean(self, csv_path: str) -> pd.DataFrame:
        df = pd.read_csv(csv_path)
        before = len(df)
        df = df.dropna(subset=["latitude", "longitude", "risk_score", "city"])
        df = df[(df["latitude"].between(-90, 90)) & (df["longitude"].between(-180, 180))]
        print(f"[DBSCAN preprocessing] {before} records loaded, {len(df)} kept after cleaning")
        return df

    def _run_dbscan_per_city(self):
        eps_rad = self.eps_km / 6371.0
        raw_clusters = []
        total_noise = 0

        # Group by city FIRST, then run DBSCAN independently within each
        # city's own records. This guarantees clusters never cross city
        # boundaries and each city's hotspot count reflects only its own
        # accident distribution.
        for city, grp in self.df.groupby("city"):
            coords_rad = np.radians(grp[["latitude", "longitude"]].values)
            db = DBSCAN(eps=eps_rad, min_samples=self.min_samples, metric="haversine")
            labels = db.fit_predict(coords_rad)

            grp = grp.copy()
            grp["cluster"] = labels
            n_clusters = len(set(labels)) - (1 if -1 in labels else 0)
            n_noise = int((labels == -1).sum())
            total_noise += n_noise
            print(f"[DBSCAN] {city}: {len(grp)} records -> {n_clusters} clusters, {n_noise} noise")

            for cid, cgrp in grp[grp["cluster"] != -1].groupby("cluster"):
                center_lat = cgrp["latitude"].mean()
                center_lng = cgrp["longitude"].mean()
                dists = cgrp.apply(
                    lambda r: _haversine_m(center_lat, center_lng, r["latitude"], r["longitude"]),
                    axis=1,
                )
                radius_m = int(min(max(dists.quantile(0.9), 300), 1500))
                raw_clusters.append({
                    "city": city,
                    "cluster_id": int(cid),
                    "center_lat": round(center_lat, 5),
                    "center_lng": round(center_lng, 5),
                    "radius_m": radius_m,
                    "incident_count": len(cgrp),
                    "avg_risk_score": round(cgrp["risk_score"].mean(), 3),
                    "fatal_rate_pct": round((cgrp["accident_severity"] == "fatal").mean() * 100, 1),
                })

        print(f"[DBSCAN] TOTAL across all cities: {len(raw_clusters)} clusters, {total_noise} noise points")

        scores = [c["avg_risk_score"] for c in raw_clusters]
        q1, q2 = np.quantile(scores, [0.33, 0.66])

        def bucket(score):
            if score >= q2:
                return "high"
            if score >= q1:
                return "medium"
            return "low"

        self.clusters = [
            Hotspot(
                cluster_id=c["cluster_id"], city=c["city"],
                center_lat=c["center_lat"], center_lng=c["center_lng"],
                radius_m=c["radius_m"], incident_count=c["incident_count"],
                avg_risk_score=c["avg_risk_score"], fatal_rate_pct=c["fatal_rate_pct"],
                risk_level=bucket(c["avg_risk_score"]),
            )
            for c in raw_clusters
        ]
        self.clusters.sort(key=lambda h: h.avg_risk_score, reverse=True)

    def all_hotspots(self) -> List[Hotspot]:
        return self.clusters

    def top_hotspots(self, n: int = 40) -> List[Hotspot]:
        return self.clusters[:n]

    def hotspots_by_city(self, city: str) -> List[Hotspot]:
        return [c for c in self.clusters if c.city.lower() == city.lower()]

    def nearest_hotspot(self, lat: float, lng: float):
        if not self.clusters:
            return None, None
        best, best_dist = None, float("inf")
        for c in self.clusters:
            d = _haversine_m(lat, lng, c.center_lat, c.center_lng)
            if d < best_dist:
                best, best_dist = c, d
        return best, best_dist

    def nearby_hotspots(self, lat: float, lng: float, radius_m: float = 500) -> List[Hotspot]:
        result = []
        for c in self.clusters:
            d = _haversine_m(lat, lng, c.center_lat, c.center_lng)
            if d <= radius_m + c.radius_m:
                result.append(c)
        return result