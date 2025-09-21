import 'package:flutter/material.dart';
import 'map_tab.dart';
import 'recommendations_tab.dart';
import 'health_insights_tab.dart';
import 'run_coach_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapTab(),
    const RecommendationsTab(),
    const HealthInsightsTab(),
    const RunCoachTab(),
    const ProfileTab(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Map',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb),
      label: 'Advice',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: 'Health',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.directions_run),
      label: 'Run Coach',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navigationItems,
      ),
    );
  }
}