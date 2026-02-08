// custom_fab.dart, to handle the floating action button that is used across all screens on the navbar

import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  // tap handler passed from teh screen using the fab
  final VoidCallback? onPressed; // nullable
  // flexible non harcoded icon
  final Widget child;
  final Color? backgroundColor;

  const CustomFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return FloatingActionButton(
      // delegate iteraction logic to the caller
      onPressed: onPressed,
      backgroundColor: isEnabled
          ? (backgroundColor ?? Theme.of(context).colorScheme.primary)
          : theme.colorScheme.surfaceContainerHigh,
      elevation: isEnabled ? 6 : 0,
      child: IconTheme(
        data: IconThemeData(
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withAlpha(97)),
        // generic content
        child: child,
      ),
    );
  }
}
