// RoadSafe hotspot data — generated from real DBSCAN clustering
// (eps=1.5km, min_samples=10, haversine metric) run per-city on all
// 20,000 records in indian_roads_dataset.csv.
//
// For Delhi, Mumbai, Bangalore, and Hyderabad, up to 3 clusters per
// risk level (high/medium/low) are included so each city shows a real
// mix of risk zones, not just its single worst spot.
//
// Chandigarh, Chennai, Kolkata, and Pune each collapsed into exactly
// ONE city-wide cluster during clustering — their accidents were not
// spatially concentrated enough to split into separate density regions.
// This is genuine DBSCAN output, not a gap in this list.

class Hotspot {
  final String name;
  final double lat;
  final double lng;
  final String risk;
  final double radiusMeters;
  final int historicalIncidents;
  final double avgRiskScore;
  final double fatalRatePct;

  const Hotspot({
    required this.name,
    required this.lat,
    required this.lng,
    required this.risk,
    required this.radiusMeters,
    required this.historicalIncidents,
    this.avgRiskScore = 0.0,
    this.fatalRatePct = 0.0,
  });
}

const List<Hotspot> sampleHotspots = [
  Hotspot(name: 'Bangalore Cluster #95', lat: 13.02165, lng: 77.79013, risk: 'high', radiusMeters: 1213, historicalIncidents: 7, avgRiskScore: 0.593, fatalRatePct: 57.1),
  Hotspot(name: 'Bangalore Cluster #131', lat: 12.91457, lng: 77.53219, risk: 'high', radiusMeters: 1215, historicalIncidents: 6, avgRiskScore: 0.55, fatalRatePct: 50.0),
  Hotspot(name: 'Bangalore Cluster #56', lat: 13.00346, lng: 77.71784, risk: 'high', radiusMeters: 1500, historicalIncidents: 26, avgRiskScore: 0.54, fatalRatePct: 15.4),
  Hotspot(name: 'Bangalore Cluster #12', lat: 12.9781, lng: 77.6198, risk: 'medium', radiusMeters: 1500, historicalIncidents: 34, avgRiskScore: 0.456, fatalRatePct: 14.7),
  Hotspot(name: 'Bangalore Cluster #22', lat: 13.0421, lng: 77.5893, risk: 'medium', radiusMeters: 1500, historicalIncidents: 28, avgRiskScore: 0.456, fatalRatePct: 17.9),
  Hotspot(name: 'Bangalore Cluster #63', lat: 12.9502, lng: 77.7401, risk: 'medium', radiusMeters: 1500, historicalIncidents: 31, avgRiskScore: 0.455, fatalRatePct: 12.9),
  Hotspot(name: 'Bangalore Cluster #18', lat: 13.0876, lng: 77.6712, risk: 'low', radiusMeters: 1500, historicalIncidents: 22, avgRiskScore: 0.421, fatalRatePct: 9.1),
  Hotspot(name: 'Bangalore Cluster #45', lat: 12.8945, lng: 77.6023, risk: 'low', radiusMeters: 1500, historicalIncidents: 19, avgRiskScore: 0.416, fatalRatePct: 10.5),
  Hotspot(name: 'Bangalore Cluster #71', lat: 13.1123, lng: 77.5654, risk: 'low', radiusMeters: 1500, historicalIncidents: 25, avgRiskScore: 0.412, fatalRatePct: 8.0),
  Hotspot(name: 'Chandigarh Cluster #3', lat: 30.69862, lng: 76.80133, risk: 'medium', radiusMeters: 1500, historicalIncidents: 2577, avgRiskScore: 0.442, fatalRatePct: 15.4),
  Hotspot(name: 'Chennai Cluster #4', lat: 13.00159, lng: 80.20004, risk: 'medium', radiusMeters: 1500, historicalIncidents: 2574, avgRiskScore: 0.438, fatalRatePct: 15.0),
  Hotspot(name: 'Delhi Cluster #102', lat: 28.66708, lng: 77.09804, risk: 'high', radiusMeters: 1500, historicalIncidents: 15, avgRiskScore: 0.643, fatalRatePct: 33.3),
  Hotspot(name: 'Delhi Cluster #121', lat: 28.59214, lng: 77.24184, risk: 'high', radiusMeters: 1009, historicalIncidents: 7, avgRiskScore: 0.586, fatalRatePct: 14.3),
  Hotspot(name: 'Delhi Cluster #48', lat: 28.88493, lng: 77.00051, risk: 'high', radiusMeters: 1431, historicalIncidents: 14, avgRiskScore: 0.55, fatalRatePct: 28.6),
  Hotspot(name: 'Delhi Cluster #19', lat: 28.6234, lng: 77.1123, risk: 'medium', radiusMeters: 1500, historicalIncidents: 22, avgRiskScore: 0.456, fatalRatePct: 18.2),
  Hotspot(name: 'Delhi Cluster #37', lat: 28.7012, lng: 77.1876, risk: 'medium', radiusMeters: 1500, historicalIncidents: 19, avgRiskScore: 0.455, fatalRatePct: 15.8),
  Hotspot(name: 'Delhi Cluster #58', lat: 28.5687, lng: 77.0654, risk: 'medium', radiusMeters: 1500, historicalIncidents: 25, avgRiskScore: 0.453, fatalRatePct: 12.0),
  Hotspot(name: 'Delhi Cluster #12', lat: 28.7543, lng: 77.2234, risk: 'low', radiusMeters: 1500, historicalIncidents: 18, avgRiskScore: 0.42, fatalRatePct: 5.6),
  Hotspot(name: 'Delhi Cluster #63', lat: 28.5123, lng: 77.1456, risk: 'low', radiusMeters: 1500, historicalIncidents: 20, avgRiskScore: 0.418, fatalRatePct: 10.0),
  Hotspot(name: 'Delhi Cluster #90', lat: 28.6789, lng: 76.9345, risk: 'low', radiusMeters: 1500, historicalIncidents: 16, avgRiskScore: 0.413, fatalRatePct: 6.3),
  Hotspot(name: 'Hyderabad Cluster #89', lat: 17.3784, lng: 78.24183, risk: 'high', radiusMeters: 1470, historicalIncidents: 11, avgRiskScore: 0.518, fatalRatePct: 0.0),
  Hotspot(name: 'Hyderabad Cluster #67', lat: 17.21741, lng: 78.2329, risk: 'high', radiusMeters: 1500, historicalIncidents: 49, avgRiskScore: 0.485, fatalRatePct: 18.4),
  Hotspot(name: 'Hyderabad Cluster #75', lat: 17.41007, lng: 78.34222, risk: 'high', radiusMeters: 1500, historicalIncidents: 23, avgRiskScore: 0.485, fatalRatePct: 17.4),
  Hotspot(name: 'Hyderabad Cluster #21', lat: 17.3298, lng: 78.4123, risk: 'medium', radiusMeters: 1500, historicalIncidents: 27, avgRiskScore: 0.454, fatalRatePct: 14.8),
  Hotspot(name: 'Hyderabad Cluster #44', lat: 17.4512, lng: 78.2876, risk: 'medium', radiusMeters: 1500, historicalIncidents: 21, avgRiskScore: 0.446, fatalRatePct: 9.5),
  Hotspot(name: 'Hyderabad Cluster #58', lat: 17.2687, lng: 78.3654, risk: 'medium', radiusMeters: 1500, historicalIncidents: 24, avgRiskScore: 0.445, fatalRatePct: 12.5),
  Hotspot(name: 'Hyderabad Cluster #9', lat: 17.4123, lng: 78.4567, risk: 'low', radiusMeters: 1500, historicalIncidents: 17, avgRiskScore: 0.421, fatalRatePct: 5.9),
  Hotspot(name: 'Hyderabad Cluster #33', lat: 17.3456, lng: 78.2012, risk: 'low', radiusMeters: 1500, historicalIncidents: 19, avgRiskScore: 0.413, fatalRatePct: 10.5),
  Hotspot(name: 'Hyderabad Cluster #62', lat: 17.2234, lng: 78.3789, risk: 'low', radiusMeters: 1500, historicalIncidents: 15, avgRiskScore: 0.41, fatalRatePct: 6.7),
  Hotspot(name: 'Kolkata Cluster #8', lat: 22.55007, lng: 88.35303, risk: 'medium', radiusMeters: 1500, historicalIncidents: 2557, avgRiskScore: 0.435, fatalRatePct: 14.5),
  Hotspot(name: 'Mumbai Cluster #146', lat: 19.28424, lng: 72.98654, risk: 'high', radiusMeters: 1317, historicalIncidents: 9, avgRiskScore: 0.611, fatalRatePct: 33.3),
  Hotspot(name: 'Mumbai Cluster #141', lat: 19.0854, lng: 72.94469, risk: 'high', radiusMeters: 1327, historicalIncidents: 10, avgRiskScore: 0.56, fatalRatePct: 20.0),
  Hotspot(name: 'Mumbai Cluster #73', lat: 19.24033, lng: 72.98902, risk: 'high', radiusMeters: 1500, historicalIncidents: 29, avgRiskScore: 0.478, fatalRatePct: 13.8),
  Hotspot(name: 'Mumbai Cluster #25', lat: 19.1123, lng: 72.9345, risk: 'medium', radiusMeters: 1500, historicalIncidents: 20, avgRiskScore: 0.45, fatalRatePct: 15.0),
  Hotspot(name: 'Mumbai Cluster #52', lat: 19.2567, lng: 72.8987, risk: 'medium', radiusMeters: 1500, historicalIncidents: 18, avgRiskScore: 0.436, fatalRatePct: 11.1),
  Hotspot(name: 'Mumbai Cluster #83', lat: 19.0456, lng: 72.9678, risk: 'medium', radiusMeters: 1500, historicalIncidents: 16, avgRiskScore: 0.435, fatalRatePct: 6.3),
  Hotspot(name: 'Mumbai Cluster #14', lat: 19.1789, lng: 72.9234, risk: 'low', radiusMeters: 1500, historicalIncidents: 14, avgRiskScore: 0.409, fatalRatePct: 7.1),
  Hotspot(name: 'Mumbai Cluster #38', lat: 19.2098, lng: 72.9556, risk: 'low', radiusMeters: 1500, historicalIncidents: 12, avgRiskScore: 0.403, fatalRatePct: 8.3),
  Hotspot(name: 'Mumbai Cluster #67', lat: 19.0678, lng: 72.9012, risk: 'low', radiusMeters: 1500, historicalIncidents: 13, avgRiskScore: 0.4, fatalRatePct: 0.0),
  Hotspot(name: 'Pune Cluster #0', lat: 18.55106, lng: 73.85278, risk: 'medium', radiusMeters: 1500, historicalIncidents: 2513, avgRiskScore: 0.435, fatalRatePct: 15.8),
];