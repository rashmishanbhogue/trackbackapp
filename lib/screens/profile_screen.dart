// profile_screen.dart, for user controls and access to the settings screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_fab.dart';
import '../widgets/responsive_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController controller;
  final scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        appBar: const CustomAppBar(),
        floatingActionButton: CustomFAB(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              controller.clear();
              FocusScope.of(context).unfocus();
            }
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, size: 30),
        ),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: const ResponsiveScreen(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CustomScrollView(),
            ))));
  }
}
