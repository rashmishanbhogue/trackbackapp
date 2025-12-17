// responsive_screen.dart, to make the app responsive across devices

import 'package:flutter/material.dart';

class ResponsiveScreen extends StatelessWidget {
  final Widget child;

  const ResponsiveScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: child,
        ));
  }
}
