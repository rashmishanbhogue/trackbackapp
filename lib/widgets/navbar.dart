// navbar.dart, app's custom navbar with 5 navigations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/trends_screen.dart';
import '../screens/ideas_dump_screen.dart';
import '../screens/home_screen.dart';
import '../screens/aimetrics_screen.dart';
import '../screens/profile_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 2);

class CustomNavBar extends ConsumerWidget {
  // uses provider-driven tab index so other screens can switch tabs without pushing routes
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    return Scaffold(
      // preserve tab state (text, scroll, focus - esp home inputfield text) while switching tabs
      body: IndexedStack(
        index: currentIndex,
        children: const [
          TrendsScreen(),
          IdeasDumpScreen(),
          HomeScreen(),
          AiMetricsScreen(),
          ProfileScreen(),
        ],
      ),
      // material3 navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Trends'),
          NavigationDestination(
              icon: Icon(Icons.lightbulb_outline),
              selectedIcon: Icon(Icons.lightbulb),
              label: 'Ideas'),
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'AI Metrics'),
          NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'You'),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
