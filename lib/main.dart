// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import '../models/entry.dart';
import '../providers/date_entries_provider.dart';
import '../devtools/hive_seeder.dart';

void main() async {
  // set dev flag in case the seeder needs to populate data via backdoor entry
  const bool isDev = bool.fromEnvironment('IS_DEV', defaultValue: false);

  // ensure the widgets and plugins are fully initialised before the async work
  WidgetsFlutterBinding.ensureInitialized();
  //initialise hive for flutter
  await Hive.initFlutter();

  // register adapter if not already done (needed to store Entry objects)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(EntryAdapter());
  }

  final box = await Hive.openBox('trackback');
  await dotenv.load(fileName: ".env");

  // optional one-time seeding (backdoor population, to be run only once during crisis)
  // to run the seeder, use the command:
  // flutter run --dart-define=IS_DEV=true (debug/dev)
  // flutter run --profile --dart-define=IS_DEV=true
  // flutter run --release --dart-define=IS_DEV=true
  if (isDev) await runHiveSeeder();

  // launch the app with the hive box provided through riverpod
  runApp(
    ProviderScope(
      overrides: [
        hiveBoxProvider.overrideWithValue(box),
      ],
      child: const TrackBackApp(),
    ),
  );
}
