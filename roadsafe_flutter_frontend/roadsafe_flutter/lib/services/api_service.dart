import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hotspot_data.dart';

class ApiService {
  // --- IMPORTANT: set this to match how you're running the backend ---
  // Android EMULATOR talking to a backend on the SAME PC: use 10.0.2.2
  // Real PHONE talking to a backend on your PC: use your PC's LAN IP
  //   (find it with `ipconfig` on Windows, look for "IPv4 Address")
  static const String baseUrl = 'http://192.168.1.42:8000';
  // Example for a real phone: 'http://192.168.1.42:8000'

  static Future<List<Hotspot>> fetchTopHotspots({int top = 40}) async {
    final uri = Uri.parse('$baseUrl/risk/clusters/top?n=$top');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((c) {
      return Hotspot(
        name: '${c['city']} Cluster #${c['cluster_id']}',
        lat: (c['center_lat'] as num).toDouble(),
        lng: (c['center_lng'] as num).toDouble(),
        risk: c['risk_level'] as String,
        radiusMeters: (c['radius_m'] as num).toDouble(),
        historicalIncidents: c['incident_count'] as int,
        avgRiskScore: (c['avg_risk_score'] as num).toDouble(),
        fatalRatePct: (c['fatal_rate_pct'] as num).toDouble(),
      );
    }).toList();
  }
}