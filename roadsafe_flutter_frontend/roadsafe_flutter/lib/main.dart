import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/report_screen.dart';
import 'screens/analytics_screen.dart';

void main() {
  runApp(const RoadSafeApp());
}

class RoadSafeApp extends StatelessWidget {
  const RoadSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6A3D),
        scaffoldBackgroundColor: const Color(0xFFF3F1EA),
        fontFamily: 'Roboto',
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    MapScreen(),
    AlertsScreen(),
    ReportScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadSafe',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
        ],
      ),
    );
  }
}
