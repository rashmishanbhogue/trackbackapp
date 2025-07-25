// dashboard_screen.dart, display bar charts for total entries and pie charts for badges earned

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../utils/time_utils.dart';
import '../models/entry.dart';
import '../metrics/charts.dart';
import '../theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  String viewType = 'Day';
  DateTime referenceDate = DateTime.now();
  bool isBarChart = true;
  late TabController tabController;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      setState(() {
        switch (tabController.index) {
          case 0:
            viewType = 'Day';
            break;
          case 1:
            viewType = 'Week';
            break;
          case 2:
            viewType = 'Month';
            break;
          case 3:
            viewType = 'Year';
            break;
        }
        updateReferenceDate();
      });
    });
    updateReferenceDate();
  }

  void updateReferenceDate() {
    final now = DateTime.now();
    switch (viewType) {
      case 'Day':
        referenceDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        referenceDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Month':
        referenceDate = DateTime(now.year, now.month);
        break;
      case 'Year':
        referenceDate = DateTime(now.year);
        break;
    }
  }

  DateTime getFirstEntryDate() {
    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    if (allEntries.isEmpty) return DateTime.now();

    return allEntries
        .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b)
        .timestamp;
  }

  void moveReferenceDate(int direction) {
    setState(() {
      if (viewType == 'Day') {
        referenceDate = referenceDate.add(Duration(days: direction));
      } else if (viewType == 'Week') {
        referenceDate = referenceDate.add(Duration(days: 7 * direction));
      } else if (viewType == 'Month') {
        referenceDate =
            DateTime(referenceDate.year, referenceDate.month + direction);
      } else if (viewType == 'Year') {
        referenceDate = DateTime(referenceDate.year + direction);
      }
    });
  }

  String getDisplayText() {
    final now = DateTime.now();

    if (viewType == 'Day') {
      if (referenceDate.year == now.year &&
          referenceDate.month == now.month &&
          referenceDate.day == now.day) {
        return 'Today';
      } else if (referenceDate.year == now.year &&
          referenceDate.month == now.month &&
          referenceDate.day == now.day - 1) {
        return 'Yesterday';
      } else {
        return DateFormat('dd MMM').format(referenceDate);
      }
    } else if (viewType == 'Week') {
      final startOfWeek =
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (startOfWeek.isBefore(now) && now.isBefore(endOfWeek)) {
        return 'This Week';
      } else {
        return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';
      }
    } else if (viewType == 'Month') {
      if (referenceDate.year == now.year && referenceDate.month == now.month) {
        return 'This Month';
      } else {
        return DateFormat('MMMM').format(referenceDate);
      }
    } else if (viewType == 'Year') {
      if (referenceDate.year == now.year) {
        return 'This Year';
      } else {
        return referenceDate.year.toString();
      }
    }
    return '';
  }

  bool canMoveBack() {
    // final now = DateTime.now();
    final firstEntryDate = getFirstEntryDate();

    if (viewType == 'Day') {
      return referenceDate.isAfter(firstEntryDate);
    }

    if (viewType == 'Week') {
      final startOfWeek =
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1));

      return startOfWeek.isAfter(firstEntryDate);
    }

    if (viewType == 'Month') {
      final startOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);

      return startOfMonth.isAfter(firstEntryDate);
    }

    if (viewType == 'Year') {
      final startOfYear = DateTime(referenceDate.year, 1, 1);

      return startOfYear.isAfter(firstEntryDate);
    }

    return false;
  }

  bool canMoveForward() {
    final now = DateTime.now();

    if (viewType == 'Day') {
      final today = DateTime(now.year, now.month, now.day);

      return referenceDate.isBefore(today);
    }

    if (viewType == 'Week') {
      final startOfWeek = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1)); // start week mon

      final endOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + 6, // sunday of the current week
        23, 59, 59, 999, // last moment of sunday
      ); // end week sun

      final canMove = endOfWeek.isBefore(now);

      return canMove;
    }

    if (viewType == 'Month') {
      final canMove = referenceDate.year < now.year ||
          (referenceDate.year == now.year && referenceDate.month < now.month);

      return canMove;
    }

    if (viewType == 'Year') {
      final canMove = referenceDate.year < now.year;

      return canMove;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateEntries = ref.watch(dateEntriesProvider);
    final isDark = theme.brightness == Brightness.dark;

    final selectedColor = theme.appBarTheme.iconTheme?.color ??
        (isDark ? AppTheme.baseWhite : AppTheme.baseBlack);
    final unselectedColor =
        isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight;

    final dataMap = <String, int>{};
    for (var entry in dateEntries.entries) {
      dataMap[entry.key] = entry.value.length;
    }

    final hasData = dataMap.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackBack'),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
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
      floatingActionButton: hasData
          ? FloatingActionButton(
              backgroundColor: theme.colorScheme.primary,
              child: Icon(isBarChart ? Icons.pie_chart : Icons.bar_chart),
              onPressed: () {
                setState(() {
                  isBarChart = !isBarChart;
                });
              },
            )
          : null,
      body: hasData
          ? FutureBuilder<Map<String, dynamic>>(
              future: calculateMetrics(viewType, selectedDate: referenceDate),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final metrics = snapshot.data!;
                final List<Entry> entries = metrics['entries'] as List<Entry>;

                final badgeCountMap = calculateBadgeCount(entries, viewType,
                    selectedDate: referenceDate);

                final timeOfDayCounts = snapshot.data?['times'] ?? {};

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBarChart
                                ? 'Entries Trend:'
                                : 'Badge Distribution:',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => showBadgeLegend(context),
                            tooltip: 'View Badge Details',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 20), // spacing between title and container

                      // container holding the tab section and its content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              // tabbar to take full available width
                              TabBar(
                                controller: tabController,
                                onTap: (index) {
                                  final now = DateTime.now();
                                  setState(() {
                                    if (index == 0) {
                                      viewType = 'Day';
                                      referenceDate = DateTime(
                                          now.year, now.month, now.day);
                                    } else if (index == 1) {
                                      viewType = 'Week';
                                      referenceDate = now.subtract(
                                          Duration(days: now.weekday - 1));
                                    } else if (index == 2) {
                                      viewType = 'Month';
                                      referenceDate =
                                          DateTime(now.year, now.month);
                                    } else if (index == 3) {
                                      viewType = 'Year';
                                      referenceDate = DateTime(now.year);
                                    }
                                  });
                                },
                                dividerColor: Colors.transparent,
                                indicatorColor: Colors.transparent,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                      color: selectedColor, width: 3),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: selectedColor,
                                unselectedLabelColor: unselectedColor,
                                labelStyle: const TextStyle(
                                  fontFamily: 'SF Pro',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.42,
                                  letterSpacing: 0.1,
                                ),
                                labelPadding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                tabs: const [
                                  Tab(text: 'Day'),
                                  Tab(text: 'Week'),
                                  Tab(text: 'Month'),
                                  Tab(text: 'Year'),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // dynamic text row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: canMoveBack()
                                        ? () => moveReferenceDate(-1)
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Text(
                                    getDisplayText(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: canMoveForward()
                                        ? () => moveReferenceDate(1)
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // bar graph or pie chart
                              Expanded(
                                child: TabBarView(
                                  controller: tabController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: List.generate(4, (_) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: SizedBox.expand(
                                        child: isBarChart
                                            ? buildBarChart(context, entries,
                                                viewType, referenceDate)
                                            : buildPieChart(context,
                                                badgeCountMap, viewType),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Divider(height: 16),
                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Time of Day Distribution:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    'Morning',
                                    'Afternoon',
                                    'Evening',
                                    'Night'
                                  ].map((period) {
                                    final count = timeOfDayCounts[period] ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Text(
                                        '$period : $count',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : const Center(
              child: Text('Add entries in Home to view the metrics.',
                  style: TextStyle(fontSize: 16)),
            ),
    );
  }

  Future<Map<String, dynamic>> calculateMetrics(String viewType,
      {DateTime? selectedDate}) async {
    final dateEntriesMap = ref.read(dateEntriesProvider);

    final allEntries = dateEntriesMap.values
        .where((list) => list.isNotEmpty)
        .expand((list) => list)
        .toList();

    final filteredEntries = filterEntriesByViewType(allEntries, viewType,
        selectedDate: selectedDate);

    Map<String, int> timeOfDayCounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Night': 0,
    };

    if (filteredEntries.isNotEmpty) {
      for (final entry in filteredEntries) {
        final block = getTimeOfDayBlock(entry.timestamp);
        timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
      }
    }

    return {
      'times': timeOfDayCounts,
      'entries': filteredEntries,
    };
  }

  Map<String, int> buildBadgeCountMap(List<Entry> entries, String viewType,
      {DateTime? selectedDate}) {
    final filteredEntries =
        filterEntriesByViewType(entries, viewType, selectedDate: selectedDate);

    Map<String, List<Entry>> groupedEntries = {};

    for (var entry in filteredEntries) {
      String key;

      switch (viewType) {
        case 'Day':
          key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
          break;
        case 'Week':
          final weekStart = DateTime(entry.timestamp.year,
                  entry.timestamp.month, entry.timestamp.day)
              .subtract(Duration(days: entry.timestamp.weekday - 1));
          key = DateFormat('yyyy-MM-dd').format(weekStart);
          break;
        case 'Month':
          key = DateFormat('yyyy-MM').format(entry.timestamp);
          break;
        case 'Year':
          key = DateFormat('yyyy').format(entry.timestamp);
          break;
        default:
          key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      }

      groupedEntries.putIfAbsent(key, () => []).add(entry);
    }

    Map<String, int> badgeCountMap = {};

    for (var group in groupedEntries.values) {
      int totalEntries = group.length;
      String badge = getBadgeForEntries(totalEntries);

      badgeCountMap[badge] = (badgeCountMap[badge] ?? 0) + 1;
    }

    return badgeCountMap;
  }

  Map<String, int> calculateBadgeCount(
    List<Entry> entries,
    String viewType, {
    DateTime? selectedDate,
  }) {
    Map<String, int> badgeCountMap = {
      'Yellow': 0,
      'Green': 0,
      'Blue': 0,
      'Purple': 0,
      'Red': 0,
      'Grey': 0,
    };

    // filter by the selected range (day, week, month, year)
    final filteredEntries =
        filterEntriesByViewType(entries, viewType, selectedDate: selectedDate);
    if (filteredEntries.isEmpty) return badgeCountMap;

    // group by day (not by week/month/year)
    Map<String, List<Entry>> entriesGroupedByDay = {};
    for (final entry in filteredEntries) {
      final dayKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      entriesGroupedByDay.putIfAbsent(dayKey, () => []).add(entry);
    }

    // count how many of each badge appears in the period
    for (final group in entriesGroupedByDay.values) {
      final count = group.length;
      final badge = getBadgeForEntries(count);
      badgeCountMap[badge] = (badgeCountMap[badge] ?? 0) + 1;
    }

    return badgeCountMap;
  }

  void showBadgeLegend(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🚀  Earn Badges!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var entry in [
                      {
                        'asset': 'assets/badges/badge_0.svg', // grey
                        'label': '0 entries' // grey
                      },
                      {
                        'asset': 'assets/badges/badge_1.svg', // yellow
                        'label': '1–4 entries' // yellow
                      },
                      {
                        'asset': 'assets/badges/badge_2.svg', // green
                        'label': '5–9 entries' // green
                      },
                      {
                        'asset': 'assets/badges/badge_3.svg', // blue
                        'label': '10–14 entries' // blue
                      },
                      {
                        'asset': 'assets/badges/badge_4.svg', // purple
                        'label': '15–19 entries' // purple
                      },
                      {
                        'asset': 'assets/badges/badge_5.svg', // red
                        'label': '20+ entries' // red
                      },
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(entry['asset']!,
                                width: 36, height: 36),
                            const SizedBox(width: 20),
                            Text(
                              entry['label']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
