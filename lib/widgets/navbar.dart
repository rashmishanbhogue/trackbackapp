// navbar.dart, app's custom navbar with 5 navigations

import 'package:flutter/material.dart';
import 'package:trackbackapp/screens/profile_screen.dart';
import '../screens/trends_screen.dart';
import '../screens/ideas_dump_screen.dart';
import '../screens/home_screen.dart';
import '../screens/aimetrics_screen.dart';
import '../theme.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  CustomNavBarState createState() => CustomNavBarState();
}

class CustomNavBarState extends State<CustomNavBar> {
  // default home
  int currentIndex = 2;

  // update active tab on user tap
  void onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // swap screen with a fade animation on tab change
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: getSelectedScreen(),
      ),
      // material3 navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        // order index - getselectedscreen() mapping
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined,
                color: AppTheme.iconDefaultLight),
            selectedIcon: Icon(Icons.analytics),
            label: 'Trends',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.lightbulb_outline, color: AppTheme.iconDefaultLight),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Ideas',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.iconDefaultLight),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined,
                color: AppTheme.iconDefaultLight),
            selectedIcon: Icon(Icons.assessment),
            label: 'AI Metrics',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined,
                color: AppTheme.iconDefaultLight),
            selectedIcon: Icon(Icons.account_circle),
            label: 'You',
          ),
        ],
      ),
    );
  }

  // return active screen based on the selected tab index, valuekeys for correct animationswitcher transttion
  Widget getSelectedScreen() {
    switch (currentIndex) {
      case 0:
        return const TrendsScreen(key: ValueKey('Trends'));
      case 1:
        return const IdeasDumpScreen(key: ValueKey('Ideas'));
      case 2:
        return const HomeScreen(key: ValueKey('Home'));
      case 3:
        return const AiMetricsScreen(key: ValueKey('AI Metrics'));
      case 4:
        return const ProfileScreen(key: ValueKey('You'));
      default:
        return const HomeScreen(key: ValueKey('Home'));
    }
  }
}
