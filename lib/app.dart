import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'home_screen.dart';

class TrackBackApp extends ConsumerWidget {
  const TrackBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(ThemeProvider);

    return MaterialApp(
      title: 'Trackback',
      theme: theme,
      home: const HomeScreen(),
    );
  }
}
