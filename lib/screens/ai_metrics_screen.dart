// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:langchain/langchain.dart';
// import 'settings_screen.dart';
// import '../providers/theme_provider.dart';
// import '../providers/date_entries_provider.dart';
// import '../models/entry.dart';
// import '../utils/time_utils.dart';
// import '../utils/ai_labeling.dart';
// import '../theme.dart';

// class AiMetricsScreen extends ConsumerWidget {
//   const AiMetricsScreen({super.key});

//   Future<Map<String, dynamic>> processEntries(List<Entry> allEntries) async {
//     Map<String, int> labelCounts = {};
//     Map<String, int> timeOfDayCounts = {
//       'Morning': 0,
//       'Afternoon': 0,
//       'Evening': 0
//     };

//     for (final entry in allEntries) {
//       final label = entry.label ??
//           await classifyEntry(entry.text); // used saved label if available

//       labelCounts[label] = (labelCounts[label] ?? 0) + 1;

//       final block = getTimeOfDayBlock(entry.timestamp);
//       timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
//     }

//     return {
//       'labels': labelCounts,
//       'times': timeOfDayCounts,
//     };
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final dateEntriesMap = ref.watch(dateEntriesProvider);
//     final allEntries = dateEntriesMap.values.expand((list) => list).toList();

//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('TrackBack'),
//           leading: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: IconButton(
//               icon: Icon(
//                 Theme.of(context).brightness == Brightness.light
//                     ? Icons.dark_mode
//                     : Icons.light_mode,
//               ),
//               onPressed: () {
//                 ref.read(ThemeProvider.notifier).toggleTheme();
//               },
//             ),
//           ),
//           actions: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: IconButton(
//                 icon: const Icon(Icons.settings),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const SettingsScreen()),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//         body: FutureBuilder<Map<String, dynamic>>(
//             future: processEntries(allEntries),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (!snapshot.hasData || snapshot.data == null) {
//                 return const Center(
//                   child: Text('No data available'),
//                 );
//               }

//               final labelCounts = snapshot.data!['labels'] as Map<String, int>;
//               final timeOfDayCounts =
//                   snapshot.data!['times'] as Map<String, int>;

//               return Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'AI Categorised Labels:',
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     ...labelCounts.entries.map((e) => Text(
//                           '${e.key}: ${e.value}',
//                           style: TextStyle(fontSize: 16),
//                         )),
//                     const Divider(
//                       height: 32,
//                     ),
//                     const Text(
//                       'Time of Day Distribution:',
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(
//                       height: 8,
//                     ),
//                     ...timeOfDayCounts.entries.map((e) => Text(
//                           '${e.key} : ${e.value}',
//                           style: const TextStyle(fontSize: 16),
//                         ))
//                   ],
//                 ),
//               );
//             }));
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../models/entry.dart';
import '../utils/time_utils.dart';
import '../utils/ai_labeling.dart';
import '../theme.dart';

class AiMetricsScreen extends ConsumerWidget {
  const AiMetricsScreen({super.key});

  Future<Map<String, dynamic>> processEntries(List<Entry> allEntries) async {
    Map<String, int> labelCounts = {};
    Map<String, int> timeOfDayCounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0
    };

    for (final entry in allEntries) {
      final label = entry.label ??
          await classifyEntry(entry.text); // used saved label if available

      // Debugging the label classification
      print(
          "Classified label for entry: $label"); // Log the label for each entry

      // Fallback to a default label if the classified label is null or empty
      final validLabel = label?.isNotEmpty ?? false ? label : 'Uncategorized';

      labelCounts[validLabel] = (labelCounts[validLabel] ?? 0) + 1;

      final block = getTimeOfDayBlock(entry.timestamp);
      timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
    }

    return {
      'labels': labelCounts,
      'times': timeOfDayCounts,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateEntriesMap = ref.watch(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    return Scaffold(
        appBar: AppBar(
          title: const Text('TrackBack'),
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: () {
                ref.read(ThemeProvider.notifier).toggleTheme();
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
            future: processEntries(allEntries),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text('No data available'),
                );
              }

              final labelCounts = snapshot.data!['labels'] as Map<String, int>;
              final timeOfDayCounts =
                  snapshot.data!['times'] as Map<String, int>;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Categorised Labels:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...labelCounts.entries.map((e) => Text(
                          '${e.key}: ${e.value}',
                          style: TextStyle(fontSize: 16),
                        )),
                    const Divider(
                      height: 32,
                    ),
                    const Text(
                      'Time of Day Distribution:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ...timeOfDayCounts.entries.map((e) => Text(
                          '${e.key} : ${e.value}',
                          style: const TextStyle(fontSize: 16),
                        ))
                  ],
                ),
              );
            }));
  }
}
