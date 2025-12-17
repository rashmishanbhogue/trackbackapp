// custom_appbar.dart, to generate the standard appbar across the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isProfile;

  const CustomAppBar({
    super.key,
    this.isProfile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text(
        'trackback',
        style: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 22),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: IconButton(
            icon: Icon(
              isProfile ? Icons.account_circle : Icons.account_circle_outlined,
            ),
            onPressed: () {
              if (!isProfile) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
