// app.dart, root app config

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import '../screens/splashscreen.dart';

class TrackBackApp extends ConsumerWidget {
  const TrackBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // app wide global theme driven by themeprovider (light/dark/system)
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'trackback',
      theme: theme,
      // app entry point
      home: const SplashScreen(),
    );
  }
}
