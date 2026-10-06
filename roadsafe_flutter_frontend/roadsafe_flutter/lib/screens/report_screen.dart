import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final List<Map<String, String>> _categories = [
    {'label': 'Accident', 'icon': '🚗'},
    {'label': 'Pothole', 'icon': '🕳️'},
    {'label': 'Flooding', 'icon': '🌊'},
    {'label': 'Debris', 'icon': '🪨'},
  ];
  String _selectedCategory = 'Accident';

  late Stopwatch _stopwatch;
  Timer? _timer;
  String _elapsed = '0.0s';

  String _locationText = 'Detecting your location...';
  Position? _currentPosition;

  File? _capturedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchLocation();
  }

  void _startTimer() {
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsed = '${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s';
      });
    });
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationText = 'Location services disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _locationText = 'Location permission denied');
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = pos;
        _locationText = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      setState(() => _locationText = 'Could not get location');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() => _capturedPhoto = File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $_selectedCategory report submitted — pending authority review'),
        backgroundColor: const Color(0xFF14181F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    setState(() {
      _stopwatch.reset();
      _capturedPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Report an Incident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Under 30 seconds, GPS auto-filled', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _currentPosition == null ? _locationText : 'Auto-detected · $_locationText',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _fetchLocation,
                    tooltip: 'Refresh location',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WHAT DID YOU SEE?',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: _categories.map((c) {
                      final selected = _selectedCategory == c['label'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c['label']!),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: selected ? const Color(0xFFFFF3EE) : Colors.white,
                            border: Border.all(
                              color: selected ? const Color(0xFFFF6A3D) : Colors.grey.shade300,
                              width: 1.4,
                            ),
                          ),
                          child: Center(
                            child: Text('${c['icon']}  ${c['label']}',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? const Color(0xFFFF6A3D) : Colors.black87)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ADD PHOTO (OPTIONAL)',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: _capturedPhoto == null
                        ? Container(
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1.4),
                      ),
                      child: const Center(
                          child: Text('📷 Tap to capture', style: TextStyle(color: Colors.grey, fontSize: 12.5))),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.file(_capturedPhoto!, height: 140, width: double.infinity, fit: BoxFit.cover),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _capturedPhoto = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A3D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Submit report', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('⏱ $_elapsed elapsed', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}