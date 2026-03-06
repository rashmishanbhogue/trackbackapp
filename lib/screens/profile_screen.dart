// profile_screen.dart, for user controls and access to the settings screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_navbar.dart';
import '../widgets/rewards_strip.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/responsive_screen.dart';
import '../widgets/app_dropdown.dart';
import '../theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController controller;
  final scrollController = ScrollController();

  String? selectedValue = 'Quiet'; // default mode

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        appBar: const CustomAppBar(),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ResponsiveScreen(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Profile',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.weekHighlightLight,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.baseWhite,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Dummy user name',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Quietness level: ',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 150,
                              child: AppDropdown<String>(
                                items: const ['Quiet', 'Minimal', 'Structured'],
                                value: selectedValue,
                                labelBuilder: (s) => s,
                                onChanged: (v) {
                                  setState(() {
                                    selectedValue = v;
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              "Rewards",
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(10, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {},
                              child: const Text(
                                "See all",
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.orangeAccent),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [Expanded(child: RewardsStrip())],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(10, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  ref.read(shellPageProvider.notifier).state =
                                      ShellPage.settings;
                                },
                                child: const Text(
                                  "Advanced Settings",
                                  style: TextStyle(
                                      fontSize: 15,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.orangeAccent),
                                ))
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ))));
  }
}
