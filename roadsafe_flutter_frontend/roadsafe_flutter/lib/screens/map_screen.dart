import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hotspot_data.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLatLng;
  bool _locationReady = false;
  String _statusMessage = 'Getting your location...';

  bool _alertVisible = false;
  Hotspot? _activeHotspot;
  final Set<String> _alreadyAlerted = {}; // avoid re-firing every GPS tick

  // Live hotspot data from the backend's DBSCAN clustering engine.
  // Starts with the static snapshot as a fallback, replaced once the
  // backend fetch succeeds.
  List<Hotspot> _hotspots = sampleHotspots;
  bool _usingLiveData = false;

  // Default alert radius in meters — matches your project's 500m default.
  static const double alertRadiusMeters = 500;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _loadLiveHotspots();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadLiveHotspots() async {
    try {
      final live = await ApiService.fetchTopHotspots();
      if (mounted && live.isNotEmpty) {
        setState(() {
          _hotspots = live;
          _usingLiveData = true;
        });
      }
    } catch (e) {
      // Backend unreachable - silently keep using the static fallback
      // list so the map still works for a demo even if offline.
      debugPrint('Live hotspot fetch failed, using fallback data: $e');
    }
  }

  Future<void> _initLocationTracking() async {
    // 1. Check if location services are enabled on the device at all.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'Please enable Location Services on your device.');
      return;
    }

    // 2. Check / request permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Location permission denied. Enable it in app settings.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = 'Location permission permanently denied. Enable it in Settings > Apps > RoadSafe.');
      return;
    }

    // 3. Get an initial fix immediately so the map centers on the user.
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _onNewPosition(pos, recenter: true);
    } catch (_) {
      // fall through — stream below may still succeed
    }

    // 4. Subscribe to a live location stream (updates as the driver moves).
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // meters moved before a new update fires
    );
    _positionStream =
        Geolocator.getPositionStream(locationSettings: settings).listen(
              (pos) => _onNewPosition(pos, recenter: false),
          onError: (e) {
            setState(() => _statusMessage = 'Location stream error: $e');
          },
        );
  }

  void _onNewPosition(Position pos, {required bool recenter}) {
    final latLng = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _currentLatLng = latLng;
      _locationReady = true;
    });

    if (recenter) {
      _mapController.move(latLng, 12);
    }

    _checkProximity(latLng);
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  // Core real-time logic: compares the driver's live GPS position against
  // every known hotspot and fires an alert the moment they enter its
  // combined radius (hotspot radius + configurable alert buffer).
  void _checkProximity(LatLng driverPos) {
    for (final h in _hotspots) {
      final dist = _distanceMeters(driverPos, LatLng(h.lat, h.lng));
      final triggerDistance = h.radiusMeters + alertRadiusMeters;

      if (dist <= triggerDistance) {
        if (!_alreadyAlerted.contains(h.name)) {
          _alreadyAlerted.add(h.name);
          _fireAlert(h, dist);
        }
      } else {
        // Left the zone — allow it to re-trigger if they re-enter later.
        _alreadyAlerted.remove(h.name);
      }
    }
  }

  void _fireAlert(Hotspot h, double distanceMeters) {
    setState(() {
      _activeHotspot = h;
      _alertVisible = true;
    });
    HapticFeedback.heavyImpact();
    // Voice callout would fire here via flutter_tts in production;
    // removed in this build due to a local Gradle/Kotlin plugin conflict.

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _alertVisible = false);
    });
  }

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

  // Nearby hotspots relative to the driver, sorted by distance —
  // used by the bottom sheet list.
  List<MapEntry<Hotspot, double>> get _nearbySorted {
    if (_currentLatLng == null) return [];
    final list = _hotspots
        .map((h) => MapEntry(h, _distanceMeters(_currentLatLng!, LatLng(h.lat, h.lng))))
        .toList();
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLatLng ?? const LatLng(19.5, 78.9),
            initialZoom: _currentLatLng != null ? 12 : 4.6,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.roadsafe.app',
            ),
            CircleLayer(
              circles: _hotspots
                  .map((h) => CircleMarker(
                point: LatLng(h.lat, h.lng),
                radius: h.radiusMeters,
                useRadiusInMeter: true,
                color: _riskColor(h.risk).withOpacity(0.28),
                borderColor: _riskColor(h.risk),
                borderStrokeWidth: 1.5,
              ))
                  .toList(),
            ),
            MarkerLayer(
              markers: [
                ..._hotspots.map((h) => Marker(
                  point: LatLng(h.lat, h.lng),
                  width: 34,
                  height: 34,
                  child: GestureDetector(
                    onTap: () => _showHotspotInfo(h),
                    child: Icon(Icons.circle, color: _riskColor(h.risk), size: 14),
                  ),
                )),
                // Live driver location marker
                if (_currentLatLng != null)
                  Marker(
                    point: _currentLatLng!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.navigation, color: Color(0xFF14181F), size: 30),
                  ),
              ],
            ),
          ],
        ),

        // Status banner while location isn't ready yet
        if (!_locationReady)
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_statusMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

        // Data source indicator - shows whether hotspots are live from
        // the backend's DBSCAN engine or the static fallback snapshot

        // Legend
        Positioned(left: 14, bottom: 90, child: _legend()),

        // Recenter-on-me button
        Positioned(
          right: 14,
          bottom: 90,
          child: FloatingActionButton(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            onPressed: () {
              if (_currentLatLng != null) {
                _mapController.move(_currentLatLng!, 13);
              }
            },
            child: const Icon(Icons.my_location, color: Colors.black87),
          ),
        ),

        // Nearby hotspots quick panel
        Positioned(
          right: 14,
          bottom: 148,
          child: FloatingActionButton.small(
            heroTag: 'nearby',
            backgroundColor: const Color(0xFFFF6A3D),
            onPressed: _showNearbySheet,
            child: const Icon(Icons.list, color: Colors.white),
          ),
        ),

        // Live alert banner
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          top: _alertVisible ? 0 : -160,
          left: 0,
          right: 0,
          child: _activeHotspot == null
              ? const SizedBox.shrink()
              : Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 44, 18, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE5484D), Color(0xFFC22B30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('High-risk zone ahead',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${_activeHotspot!.name} — within ${alertRadiusMeters.toInt()}m radius',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.vibration, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Haptic alert fired', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow('High risk', const Color(0xFFE5484D)),
          _legendRow('Medium risk', const Color(0xFFF5A524)),
          _legendRow('Low risk', const Color(0xFF3FB950)),
        ],
      ),
    );
  }

  Widget _legendRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  void _showHotspotInfo(Hotspot h) {
    final dist = _currentLatLng != null
        ? _distanceMeters(_currentLatLng!, LatLng(h.lat, h.lng))
        : null;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Risk level: ${h.risk.toUpperCase()}'),
            Text('Historical incidents: ${h.historicalIncidents}'),
            Text('Alert radius: ${h.radiusMeters.toInt()} m'),
            if (dist != null) Text('Distance from you: ${(dist / 1000).toStringAsFixed(1)} km'),
          ],
        ),
      ),
    );
  }

  void _showNearbySheet() {
    final list = _nearbySorted;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nearby Hotspots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _currentLatLng == null
                    ? 'Waiting for your location...'
                    : 'Sorted by distance from your live position',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No location yet'))
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final h = list[i].key;
                    final dist = list[i].value;
                    return ListTile(
                      leading: Icon(Icons.circle, size: 12, color: _riskColor(h.risk)),
                      title: Text(h.name, style: const TextStyle(fontSize: 13.5)),
                      subtitle: Text('${h.risk.toUpperCase()} risk · ${h.historicalIncidents} historical incidents'),
                      trailing: Text(
                        dist < 1000 ? '${dist.toInt()} m' : '${(dist / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}