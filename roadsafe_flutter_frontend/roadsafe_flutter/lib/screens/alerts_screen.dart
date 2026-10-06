import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/hotspot_data.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLatLng;
  bool _locationReady = false;
  String _statusMessage = 'Getting your location...';

  // Live hotspot data from the backend's DBSCAN clustering engine.
  // Starts with the static snapshot as a fallback, replaced once the
  // backend fetch succeeds.
  List<Hotspot> _hotspots = sampleHotspots;
  bool _usingLiveData = false;

  static const double alertRadiusMeters = 500;

  @override
  void initState() {
    super.initState();
    _initLocation();
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
      // list so the screen still works for a demo even if offline.
      debugPrint('Live hotspot fetch failed, using fallback data: $e');
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'Please enable Location Services.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = 'Location permission permanently denied.');
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _locationReady = true;
      });
    } catch (_) {}

    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15);
    _positionStream = Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _locationReady = true;
      });
    });
  }

  double _distanceMeters(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);

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

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    if (!_locationReady) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    // Real distance from the driver to every hotspot, sorted nearest-first.
    final withDistance = _hotspots
        .map((h) => MapEntry(h, _distanceMeters(_currentLatLng!, LatLng(h.lat, h.lng))))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // "Active" = genuinely inside the hotspot's radius + alert buffer.
    final active = withDistance
        .where((e) => e.value <= e.key.radiusMeters + alertRadiusMeters)
        .toList();

    final upcoming = withDistance.where((e) => !active.contains(e)).take(6).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (_usingLiveData ? const Color(0xFF3FB950) : Colors.grey).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _usingLiveData ? 'Live DBSCAN' : 'Offline snapshot',
                  style: TextStyle(
                    color: _usingLiveData ? const Color(0xFF1B7A3D) : Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Text('Live monitoring within 500m radius', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 16),

          if (active.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('No hotspots within range right now.',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...active.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE5484D), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE NOW',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(e.key.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDistance(e.value)} away · ${e.key.historicalIncidents} historical incidents',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )),
          const SizedBox(height: 6),

          const Text('NEARBY (SORTED BY DISTANCE)',
              style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: upcoming.isEmpty
                  ? [const Padding(padding: EdgeInsets.all(16), child: Text('No other hotspots loaded.'))]
                  : upcoming
                  .map((e) => ListTile(
                leading: Icon(Icons.circle, size: 12, color: _riskColor(e.key.risk)),
                title: Text(e.key.name, style: const TextStyle(fontSize: 13.5)),
                trailing: Text(_formatDistance(e.value),
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold)),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ALERT SETTINGS',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 10),
                  _SettingRow(label: 'Alert radius', value: '500 m'),
                  _SettingRow(label: 'Haptic feedback', value: 'ON', on: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool on;
  const _SettingRow({required this.label, required this.value, this.on = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: on ? Colors.green : Colors.black)),
        ],
      ),
    );
  }
}