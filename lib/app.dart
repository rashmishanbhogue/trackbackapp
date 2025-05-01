// app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackbackapp/widgets/navbar.dart';
import 'providers/theme_provider.dart';

class TrackBackApp extends ConsumerWidget {
  const TrackBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(ThemeProvider);

    return MaterialApp(
      title: 'Trackback',
      theme: theme,
      home: CustomNavBar(),
    );
  }
}
