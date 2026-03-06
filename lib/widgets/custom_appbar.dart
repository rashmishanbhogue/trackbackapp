// custom_appbar.dart, to generate the standard appbar across the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
            child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              // border: Border.all(color: AppTheme.weekHighlightLight, width: 2),
              color: AppTheme.weekHighlightLight),
          alignment: Alignment.center,
          child: const Text(
            "t",
            style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
        )),
      ),
      actions: const [
        Padding(padding: EdgeInsets.only(right: 26), child: Icon(Icons.search))
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
