// custom_fab.dart, to handle the floating action button that is used across all screens on the navbar

import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  // tap handler passed from teh screen using the fab
  final VoidCallback onPressed;
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
    return FloatingActionButton(
      // delegate iteraction logic to the caller
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      // generic content
      child: child,
    );
  }
}
