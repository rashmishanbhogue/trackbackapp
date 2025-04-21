import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/ai_metrics_screen.dart';
import '../screens/settings_screen.dart';

class CustomNavBar extends StatefulWidget {
  @override
  CustomNavBarState createState() => CustomNavBarState();
}

class CustomNavBarState extends State<CustomNavBar> {
  int currentIndex = 1;

  void onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: getSelectedScreen(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'AI Metrics',
          ),
        ],
      ),
    );
  }

  Widget getSelectedScreen() {
    switch (currentIndex) {
      case 0:
        return const DashboardScreen(key: ValueKey('Dashboard'));
      case 1:
        return const HomeScreen(key: ValueKey('Home'));
      case 2:
        return const AiMetricsScreen(key: ValueKey('AI Metrics'));
      case 3:
        return const SettingsScreen(key: ValueKey('Settings'));
      default:
        return const HomeScreen(key: ValueKey('Home'));
    }
  }
}
