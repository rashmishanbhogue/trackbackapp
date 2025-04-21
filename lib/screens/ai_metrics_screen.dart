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
import '../utils/constants.dart';

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
    Map<String, List<Entry>> labelToEntries = {};

    final storedLabels = await getLabelsFromHive();
    labelCounts.addAll(storedLabels);

    if (labelCounts.isNotEmpty) {
      for (final entry in allEntries) {
        final block = getTimeOfDayBlock(entry.timestamp);
        timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
      }
      return {
        'labels': labelCounts,
        'times': timeOfDayCounts,
        'entries': labelToEntries, // empty if loading from hive
      };
    }

    for (final entry in allEntries) {
      String label = entry.label;
      if (label.isEmpty) {
        label = await classifyEntry(entry.text);
      }
      final validLabel = label.isNotEmpty ? label : 'Uncategorized';
      final category = getBroaderCategory(validLabel);

      labelCounts[category] = (labelCounts[category] ?? 0) + 1;
      labelToEntries.putIfAbsent(category, () => []).add(entry);

      final block = getTimeOfDayBlock(entry.timestamp);
      timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
    }

    await storeLabelsInHive(labelCounts);
    return {
      'labels': labelCounts,
      'times': timeOfDayCounts,
      'entries': labelToEntries,
    };
  }

  String getBroaderCategory(String label) {
    if (standardCategories.contains(label)) {
      return label;
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
          final labelToEntries =
              snapshot.data!['entries'] as Map<String, List<Entry>>;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
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

                  /// build the category chips
                  ...standardCategories.map((category) {
                    final count = labelCounts[category] ?? 0;
                    final entries = labelToEntries[category] ?? [];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        trailing: const SizedBox.shrink(),
                        title: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: getCategoryColor(category, isDark),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: isRefreshing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$category: $count',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    '$category: $count',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                        children: entries.isNotEmpty
                            ? entries
                                .map((entry) => ListTile(
                                      title: Text(
                                        entry.text,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('dd MMM, HH:mm')
                                            .format(entry.timestamp),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                    ))
                                .toList()
                            : [
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                      'No entries found for this category.'),
                                ),
                              ],
                      ),
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

  Color getCategoryColor(String category, bool isDark) {
    switch (category) {
      case 'Productive':
        return isDark ? Colors.blue.shade200 : Colors.blue.shade100;
      case 'Maintenance':
        return isDark ? Colors.grey.shade500 : Colors.grey.shade200;
      case 'Wellbeing':
        return isDark ? Colors.green.shade200 : Colors.green.shade100;
      case 'Leisure':
        return isDark ? Colors.purple.shade200 : Colors.purple.shade100;
      case 'Social':
        return isDark ? Colors.pink.shade200 : Colors.pink.shade100;
      case 'Idle':
        return isDark ? Colors.grey.shade700 : Colors.grey.shade400;
      default:
        return Colors.grey.shade200;
    }
  }
}
