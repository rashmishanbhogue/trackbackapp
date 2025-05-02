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
import '../theme.dart';

enum TimeFilter { all, day, week, month, year }

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
  String? expandedCategory;

  TimeFilter selectedFilter = TimeFilter.all;
  final ScrollController chipScrollController = ScrollController();
  final List<GlobalKey> chipKeys =
      List.generate(TimeFilter.values.length, (_) => GlobalKey());

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
              buildFilterChips(theme, isDark),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              ...standardCategories.map((category) {
                final count = labelCounts[category] ?? 0;
                final entries = (labelToEntries[category] ?? [])
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        expandedCategory = null;
                      });
                    },
                    child: ExpansionTile(
                      initiallyExpanded: expandedCategory == category,
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
                                  const SizedBox(
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
                              ),
                            ]
                          : [
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child:
                                    Text('No entries found for this category.'),
                              ),
                            ],
                    ),
                  ),
                );
              }),
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
        return isDark ? AppTheme.productiveDark : AppTheme.productiveLight;
      case 'Maintenance':
        return isDark ? AppTheme.maintenanceDark : AppTheme.maintenanceLight;
      case 'Wellbeing':
        return isDark ? AppTheme.wellbeingDark : AppTheme.wellbeingLight;
      case 'Leisure':
        return isDark ? AppTheme.leisureDark : AppTheme.leisureLight;
      case 'Social':
        return isDark ? AppTheme.socialDark : AppTheme.socialLight;
      case 'Idle':
        return isDark ? AppTheme.idleDark : AppTheme.idleLight;
      default:
        return Colors.grey.shade200;
    }
  }

  // background expansion chip entries lighter colour
  Color getLighterCategoryColor(String category, bool isDark) {
    switch (category) {
      case 'Productive':
        return isDark
            ? AppTheme.productiveDarkest
            : AppTheme.productiveLightest;
      case 'Maintenance':
        return isDark
            ? AppTheme.maintenanceDarkest
            : AppTheme.maintenanceLightest;
      case 'Wellbeing':
        return isDark
            ? AppTheme.maintenanceDarkest
            : AppTheme.wellbeingLightest;
      case 'Leisure':
        return isDark ? AppTheme.leisureDarkest : AppTheme.leisureLightest;
      case 'Social':
        return isDark ? AppTheme.socialDarkest : AppTheme.socialLightest;
      case 'Idle':
        return isDark ? AppTheme.idleDarkest : AppTheme.idleLightest;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget buildFilterChips(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          controller: chipScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TimeFilter.values.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: RawChip(
                  key: chipKeys[index],
                  label: Text(
                    filter.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedFilter = filter;
                      });
                      scrollToSelectedChip(index);
                    }
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: theme.colorScheme.primary.withOpacity(0.6),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          // theme.colorScheme.primary
                          : Colors.grey.shade400,
                      width: 1.2,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void scrollToSelectedChip(int index) {
    final keyContext = chipKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    }
  }

  List<DateTime> getAvailableDates(List<Entry> entries) {
    return entries.map((entry) => entry.timestamp).toSet().toList();
  }

  List<int> getAvailableMonths(List<Entry> entries) {
    return entries.map((entry) => entry.timestamp.month).toSet().toList();
  }

  List<int> getAvailableYears(List<Entry> entries) {
    return entries.map((entry) => entry.timestamp.year).toSet().toList();
  }

  List<String> getAvailableWeeks(List<Entry> entries) {
    return entries
        .map((entry) {
          final startOfWeek = entry.timestamp
              .subtract(Duration(days: entry.timestamp.weekday - 1));
          return "${startOfWeek.year}-${startOfWeek.month}-${startOfWeek.day}";
        })
        .toSet()
        .toList();
  }

  void showFilterModal(
      BuildContext context, TimeFilter filter, List<Entry> entries) {
    switch (filter) {
      case TimeFilter.day:
        final availableDates = getAvailableDates(entries);
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select a Day",
                      style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableDates.length,
                      itemBuilder: (context, index) {
                        final date = availableDates[index];
                        return ListTile(
                          title: Text(date.toLocal().toString()),
                          onTap: () {
                            setState(() {
                              selectedFilter = TimeFilter.day;
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case TimeFilter.week:
        final availableWeeks = getAvailableWeeks(entries);
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select a Week",
                      style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableWeeks.length,
                      itemBuilder: (context, index) {
                        final week = availableWeeks[index];
                        return ListTile(
                          title: Text("Week: $week"),
                          onTap: () {
                            setState(() {
                              selectedFilter = TimeFilter.week;
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case TimeFilter.month:
        final availableMonths = getAvailableMonths(entries);
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select a Month",
                      style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableMonths.length,
                      itemBuilder: (context, index) {
                        final month = availableMonths[index];
                        return ListTile(
                          title: Text("Month: $month"),
                          onTap: () {
                            setState(() {
                              selectedFilter = TimeFilter.month;
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case TimeFilter.year:
        final availableYears = getAvailableYears(entries);
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select a Year",
                      style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableYears.length,
                      itemBuilder: (context, index) {
                        final year = availableYears[index];
                        return ListTile(
                          title: Text("Year: $year"),
                          onTap: () {
                            setState(() {
                              selectedFilter = TimeFilter.year;
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      default:
        break;
    }
  }
}
