// navbar.dart, app's custom navbar with 5 navigations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/trends_screen.dart';
import '../screens/ideas_dump_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

// high level app destinations - ui states, not navigator routes
enum ShellPage {
  trends,
  home,
  you,
  ideas, // logical page that reuses home tab selection
}

// single source of truth for which top-level page is visible
final shellPageProvider = StateProvider<ShellPage>((ref) => ShellPage.home);

class CustomNavBar extends ConsumerWidget {
  // shell style navgiation to switch pages without pushing routes
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(shellPageProvider);

    // resolve visible screen from shell state
    Widget body;
    switch (page) {
      case ShellPage.trends:
        body = const TrendsScreen();
        break;
      case ShellPage.home:
        body = const HomeScreen();
        break;
      case ShellPage.you:
        body = const ProfileScreen();
        break;
      case ShellPage.ideas:
        body = const IdeasDumpScreen(); // idea is a full page, not a tab
        break;
    }
    return Scaffold(
      // preserve tab state (text, scroll, focus - esp home inputfield text) while switching tabs
      body: body,

      // bottom nav contains only 3 primary tabs, not all pages
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexFromPage(page),
        onDestinationSelected: (index) {
          ref.read(shellPageProvider.notifier).state = pageFromIndex(index);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Trends'),
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'You'),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  // map shell pages to bpttom nav indices
  int indexFromPage(ShellPage page) {
    switch (page) {
      case ShellPage.trends:
        return 0;
      case ShellPage.home:
      case ShellPage.ideas: // idea lighlights to home tab
        return 1;
      case ShellPage.you:
        return 2;
    }
  }

  // map bottom nav taps back to shell pages
  ShellPage pageFromIndex(int index) {
    switch (index) {
      case 0:
        return ShellPage.trends;
      case 1:
        return ShellPage.home;
      case 2:
        return ShellPage.you;
      default:
        return ShellPage.home;
    }
  }
}
