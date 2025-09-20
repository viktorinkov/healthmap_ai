import 'package:flutter/material.dart';
import 'map_tab.dart';
import 'recommendations_tab.dart';
import 'daily_tasks_tab.dart';
import 'running_coach_tab.dart';
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
    const DailyTasksTab(),
    const RunningCoachTab(),
    const ProfileTab(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Map',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb),
      label: 'Recommendations',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.task_alt),
      label: 'Daily Tasks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.directions_run),
      label: 'Running Coach',
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