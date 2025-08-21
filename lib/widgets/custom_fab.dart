// custom_fab.dart, to handle the floating action button that is used across all screens on the navbar

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
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
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
