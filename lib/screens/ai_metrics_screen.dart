import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../models/entry.dart';
import '../utils/time_utils.dart';
import '../utils/ai_labeling.dart';
import '../utils/hive_utils.dart';

class AiMetricsScreen extends ConsumerStatefulWidget {
  const AiMetricsScreen({super.key});

  @override
  ConsumerState<AiMetricsScreen> createState() => AiMetricsScreenState();
}

class AiMetricsScreenState extends ConsumerState<AiMetricsScreen> {
  late Future<Map<String, dynamic>> futureMetrics;
  bool isRefreshing = false;
  bool isInitialLoad = true;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    futureMetrics = calculateMetrics();

    // load the stored last updated timestamp on screen load (last api call to groq)
    getLastUpdatedFromHive().then((timestamp) {
      if (mounted) {
        setState(() {
          lastUpdated = timestamp;
        });
      }
    });
  }

  Future<Map<String, dynamic>> calculateMetrics() async {
    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    Map<String, int> labelCounts = {};
    Map<String, int> timeOfDayCounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0
    };

    for (final entry in allEntries) {
      String label = entry.label;
      if (label.isEmpty) {
        label = await classifyEntry(entry.text);
      }

      final validLabel = label.isNotEmpty ? label : 'Uncategorized';
      final category = getBroaderCategory(validLabel);
      labelCounts[category] = (labelCounts[category] ?? 0) + 1;

      final block = getTimeOfDayBlock(entry.timestamp);
      timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
    }

    await storeLabelsInHive(labelCounts);
    return {
      'labels': labelCounts,
      'times': timeOfDayCounts,
    };
  }

  String getBroaderCategory(String label) {
    const broaderCategories = {
      'Work': ['bug fix', 'development', 'programming', 'office', 'test'],
      'Chores': ['cook', 'meal', 'dinner', 'breakfast', 'lunch', 'clean'],
      'Errands': ['shopping', 'bank', 'temple'],
      'Health': ['workout', 'exercise', 'health', 'walk'],
      'Distraction': [
        'social',
        'gaming',
        'tv',
        'youtube',
        'phone',
        'instagram'
      ],
    };

    final lowerLabel = label.toLowerCase();

    for (var category in broaderCategories.keys) {
      for (var keyword in broaderCategories[category]!) {
        if (lowerLabel.contains(keyword)) {
          return category;
        }
      }
    }
    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackBack'),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
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
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: futureMetrics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              isRefreshing) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                final now = DateTime.now();
                await storeLastUpdatedInHive(now);
                setState(() {
                  lastUpdated = now;
                  isRefreshing = false;
                });
              }
            });
          }

          return FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            child: isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: () async {
              if (!isRefreshing) {
                setState(() {
                  isRefreshing = true;
                  isInitialLoad = false;
                });
                await clearStoredLabels();
                setState(() {
                  futureMetrics = calculateMetrics();
                });
              }
            },
          );
        },
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureMetrics,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          }

          final labelCounts = snapshot.data!['labels'] as Map<String, int>;
          final timeOfDayCounts = snapshot.data!['times'] as Map<String, int>;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'AI Categorised Labels:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (lastUpdated != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Last updated: ${DateFormat('dd-MMM-yy, HH:mm').format(lastUpdated!)} hrs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...labelCounts.entries.map((e) {
                    return Row(
                      children: [
                        Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (isRefreshing)
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                  const Divider(height: 32),
                  const Text(
                    'Time of Day Distribution:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...timeOfDayCounts.entries.map((e) {
                    return Text(
                      '${e.key} : ${e.value}',
                      style: const TextStyle(fontSize: 16),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
