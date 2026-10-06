import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/hotspot_data.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  LatLng? _checkedPoint;
  Hotspot? _nearestCluster;
  double? _nearestDistance;

  Color _riskColor(String risk) {
    switch (risk) {
      case 'high':
        return const Color(0xFFE5484D);
      case 'medium':
        return const Color(0xFFF5A524);
      default:
        return const Color(0xFF3FB950);
    }
  }

  double _distanceMeters(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);

  void _checkLocation(LatLng point) {
    Hotspot? nearest;
    double bestDist = double.infinity;
    for (final h in sampleHotspots) {
      final d = _distanceMeters(point, LatLng(h.lat, h.lng));
      if (d < bestDist) {
        bestDist = d;
        nearest = h;
      }
    }
    setState(() {
      _checkedPoint = point;
      _nearestCluster = nearest;
      _nearestDistance = bestDist;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort clusters by risk for the top-clusters list.
    final sorted = [...sampleHotspots]
      ..sort((a, b) => b.avgRiskScore.compareTo(a.avgRiskScore));
    final highCount = sampleHotspots.where((h) => h.risk == 'high').length;
    final mediumCount = sampleHotspots.where((h) => h.risk == 'medium').length;
    final lowCount = sampleHotspots.where((h) => h.risk == 'low').length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('DBSCAN clustering results · full dataset',
              style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              _StatCard(num: '${sampleHotspots.length}', label: 'Clusters shown'),
              _StatCard(num: '$highCount', label: 'High-risk clusters'),
              _StatCard(num: '$mediumCount', label: 'Medium-risk clusters'),
              _StatCard(num: '$lowCount', label: 'Low-risk clusters'),
            ],
          ),
          const SizedBox(height: 20),

          // ---------------- Top hotspot clusters ----------------
          const Text('Top Hotspot Clusters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('Ranked by average risk score from DBSCAN clustering',
              style: TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: sorted.take(10).map((h) {
                return ListTile(
                  leading: Icon(Icons.circle, size: 12, color: _riskColor(h.risk)),
                  title: Text(h.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${h.historicalIncidents} incidents · ${h.fatalRatePct.toStringAsFixed(1)}% fatal rate',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    h.avgRiskScore.toStringAsFixed(3),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _riskColor(h.risk)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ---------------- Tap-to-check location tool ----------------
          const Text('Check a Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Text('Tap anywhere on the map to find the nearest DBSCAN cluster',
              style: TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 10),

          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(20.5, 78.9),
                  initialZoom: 4.2,
                  onTap: (tapPosition, point) => _checkLocation(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.roadsafe.app',
                  ),
                  CircleLayer(
                    circles: sampleHotspots
                        .map((h) => CircleMarker(
                      point: LatLng(h.lat, h.lng),
                      radius: h.radiusMeters,
                      useRadiusInMeter: true,
                      color: _riskColor(h.risk).withOpacity(0.25),
                      borderColor: _riskColor(h.risk),
                      borderStrokeWidth: 1,
                    ))
                        .toList(),
                  ),
                  MarkerLayer(
                    markers: [
                      ...sampleHotspots.map((h) => Marker(
                        point: LatLng(h.lat, h.lng),
                        width: 20,
                        height: 20,
                        child: Icon(Icons.circle, color: _riskColor(h.risk), size: 10),
                      )),
                      if (_checkedPoint != null)
                        Marker(
                          point: _checkedPoint!,
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_pin, color: Color(0xFF14181F), size: 34),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_nearestCluster != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _riskColor(_nearestCluster!.risk),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nearestCluster!.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${(_nearestDistance! / 1000).toStringAsFixed(1)} km away · ${_nearestCluster!.historicalIncidents} historical incidents',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                        Text(
                          'Avg risk score: ${_nearestCluster!.avgRiskScore.toStringAsFixed(3)} · ${_nearestCluster!.fatalRatePct.toStringAsFixed(1)}% fatal rate',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_nearestCluster!.risk} Risk'.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Tap the map above to check a location.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String num;
  final String label;
  const _StatCard({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(num, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}