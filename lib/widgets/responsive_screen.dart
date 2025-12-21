// responsive_screen.dart, to make the app responsive across devices

import 'package:flutter/material.dart';

class ResponsiveScreen extends StatelessWidget {
  // actua lscreen content passed by the caller
  final Widget child;

  const ResponsiveScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
        // avoid stretched layout on wider screens
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // hard cap on width to preserve mobile-first design
          constraints: const BoxConstraints(maxWidth: 420),
          // render screens actual content within constraints
          child: child,
        ));
  }
}
