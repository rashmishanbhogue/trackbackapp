import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../models/entry.dart';
import '../utils/ai_labeling.dart';
import '../utils/hive_utils.dart';
import '../utils/constants.dart';

class AiMetricsScreen extends ConsumerStatefulWidget {
  const AiMetricsScreen({super.key});

  @override
  ConsumerState<AiMetricsScreen> createState() => AiMetricsScreenState();
}

class AiMetricsScreenState extends ConsumerState<AiMetricsScreen> {
  bool isRefreshing = false;
  Map<String, int> labelCounts = {};
  Map<String, List<Entry>> labelToEntries = {};
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    loadStoredMetrics(); // load the metrics immediately on page load
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadStoredMetrics(); // reload data when navigating back to the page
  }

  Future<void> loadStoredMetrics() async {
    final storedLabels = await getLabelsFromHive();
    final timestamp = await getLastUpdatedFromHive();
    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    // map to group entries by category
    Map<String, List<Entry>> entriesByCategory = {};

    // populate entriesByCategory map with entries from allEntries
    for (final entry in allEntries) {
      String label = entry.label;

      if (label.isNotEmpty) {
        final category = getBroaderCategory(label);

        // only add entries that have a matching category in storedLabels
        if (storedLabels.containsKey(category)) {
          entriesByCategory.putIfAbsent(category, () => []).add(entry);
        }
      }
    }

    setState(() {
      labelCounts = {...storedLabels}; // copy the stored counts
      labelToEntries = entriesByCategory; // set the entries map
      lastUpdated = timestamp; // set the last updated timestamp
    });
  }

  Future<void> refreshMetrics() async {
    setState(() {
      isRefreshing = true;
    });

    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    Map<String, int> newLabelCounts = {};
    Map<String, List<Entry>> newLabelToEntries = {};
    Map<String, List<Entry>> updatedEntriesByDate = {};

    for (final entry in allEntries) {
      String label = entry.label;
      if (label.isEmpty) {
        label = await classifyEntry(entry.text);
      }

      final validLabel = label.isNotEmpty ? label : 'Uncategorized';
      final category = getBroaderCategory(validLabel);

      final updatedEntry = entry.copyWith(label: validLabel);

      newLabelCounts[category] = (newLabelCounts[category] ?? 0) + 1;
      newLabelToEntries.putIfAbsent(category, () => []).add(updatedEntry);

      final dateKey = DateFormat('yyyy-MM-dd').format(updatedEntry.timestamp);
      updatedEntriesByDate.putIfAbsent(dateKey, () => []).add(updatedEntry);
    }

    await storeLabelsInHive(newLabelCounts);
    final now = DateTime.now();
    await storeLastUpdatedInHive(now);

    // update the provider and persist updated entries with their new labels
    ref.read(dateEntriesProvider.notifier).replaceAll(updatedEntriesByDate);

    setState(() {
      labelCounts = newLabelCounts;
      labelToEntries = newLabelToEntries;
      lastUpdated = now;
      isRefreshing = false;
    });
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
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
            });
            await clearStoredLabels();
            await refreshMetrics();
          }
        },
      ),
      body: Padding(
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
              const SizedBox(height: 15),
              Center(
                child: Text(
                  lastUpdated != null
                      ? 'Last updated: ${DateFormat('dd-MMM-yy, HH:mm').format(lastUpdated!)} hrs'
                      : 'Last updated: Never. Add entries in Home and press Refresh button here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
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
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                '$category: $count',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    children: entries.isNotEmpty
                        ? [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: getLighterCategoryColor(
                                          category, isDark),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(30),
                                        bottomRight: Radius.circular(30),
                                      ),
                                    ),
                                    child: Column(
                                      children: entries.map((entry) {
                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                          title: Text(
                                            entry.text,
                                            style: const TextStyle(
                                                color: Colors.black87),
                                          ),
                                          subtitle: Text(
                                            DateFormat('dd MMM, HH:mm')
                                                .format(entry.timestamp),
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 28),
                              ],
                            )
                          ]
                        : [
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child:
                                  Text('No entries found for this category.'),
                            ),
                          ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // background expansion chip colour
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

  // background expansion chip entries colour
  Color getLighterCategoryColor(String category, bool isDark) {
    switch (category) {
      case 'Productive':
        return isDark ? Colors.blue.shade100 : Colors.blue.shade50;
      case 'Maintenance':
        return isDark ? Colors.grey.shade400 : Colors.grey.shade100;
      case 'Wellbeing':
        return isDark ? Colors.green.shade100 : Colors.green.shade50;
      case 'Leisure':
        return isDark ? Colors.purple.shade100 : Colors.purple.shade50;
      case 'Social':
        return isDark ? Colors.pink.shade100 : Colors.pink.shade50;
      case 'Idle':
        return isDark ? Colors.grey.shade600 : Colors.grey.shade300;
      default:
        return Colors.grey.shade100;
    }
  }
}
