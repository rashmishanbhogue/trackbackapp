// dashboard_screen.dart, display bar charts for total entries and pie charts for badges earned

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../utils/time_utils.dart';
import '../models/entry.dart';

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
      debugPrint(
          'Moving referenceDate. Current referenceDate: $referenceDate, Direction: $direction');

      if (viewType == 'Day') {
        referenceDate = referenceDate.add(Duration(days: direction));
        debugPrint('New referenceDate for Day: $referenceDate');
      } else if (viewType == 'Week') {
        referenceDate = referenceDate.add(Duration(days: 7 * direction));
        debugPrint('New referenceDate for Week: $referenceDate');
      } else if (viewType == 'Month') {
        referenceDate =
            DateTime(referenceDate.year, referenceDate.month + direction);
        debugPrint('New referenceDate for Month: $referenceDate');
      } else if (viewType == 'Year') {
        referenceDate = DateTime(referenceDate.year + direction);
        debugPrint('New referenceDate for Year: $referenceDate');
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
      return referenceDate.year.toString();
    }
    return '';
  }

  bool canMoveBack() {
    // final now = DateTime.now();
    final firstEntryDate = getFirstEntryDate();

    if (viewType == 'Day') {
      debugPrint('value of firstEntryDate: $firstEntryDate');
      return referenceDate.isAfter(firstEntryDate);
    }

    if (viewType == 'Week') {
      final startOfWeek =
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
      debugPrint('value of startOfWeek: $startOfWeek');

      return startOfWeek.isAfter(firstEntryDate);
    }

    if (viewType == 'Month') {
      final startOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
      debugPrint('value of startOfMonth: $startOfMonth');

      return startOfMonth.isAfter(firstEntryDate);
    }

    if (viewType == 'Year') {
      final startOfYear = DateTime(referenceDate.year, 1, 1);
      debugPrint('value of startOfYear: $startOfYear');

      return startOfYear.isAfter(firstEntryDate);
    }

    return false;
  }

  bool canMoveForward() {
    final now = DateTime.now();
    debugPrint(
        'Checking if we can move forward. Current referenceDate: $referenceDate');

    if (viewType == 'Day') {
      final today = DateTime(now.year, now.month, now.day);

      debugPrint('value of today for Day is: $today');
      return referenceDate.isBefore(today);
    }

    if (viewType == 'Week') {
      final startOfWeek = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1)); // start week mon
      debugPrint('Start of week: $startOfWeek');
      final endOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + 6, // sunday of the current week
        23, 59, 59, 999, // last moment of sunday
      ); // end week sun
      debugPrint('End of week: $endOfWeek');
      debugPrint('Today\'s date: $now');
      debugPrint('Can move forward?: ${endOfWeek.isBefore(now)}');

      final canMove = endOfWeek.isBefore(now);
      debugPrint(
          'Can move forward in Week view: $canMove (startOfWeek: $startOfWeek, endOfWeek: $endOfWeek)');
      return canMove;
    }

    if (viewType == 'Month') {
      final canMove = referenceDate.year < now.year ||
          (referenceDate.year == now.year && referenceDate.month < now.month);
      debugPrint('Can move forward in Month view: $canMove');
      return canMove;
    }

    if (viewType == 'Year') {
      final canMove = referenceDate.year < now.year;
      debugPrint('Can move forward in Year view: $canMove');
      return canMove;
    }

    debugPrint('Default return: false');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateEntries = ref.watch(dateEntriesProvider);
    final isDark = theme.brightness == Brightness.dark;

    final selectedColor = theme.appBarTheme.iconTheme?.color ??
        (isDark ? Colors.white : Colors.black);
    final unselectedColor = isDark ? Colors.white38 : Colors.black38;

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
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 20),
                      Expanded(
                        child: DefaultTabController(
                          length: 4,
                          initialIndex: 0,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 300,
                                child: TabBar(
                                  controller: tabController,
                                  onTap: (index) {
                                    final now = DateTime.now();
                                    setState(() {
                                      if (index == 0) {
                                        viewType = 'Day';
                                        referenceDate = DateTime(
                                            now.year, now.month, now.day);
                                        debugPrint(
                                            'Switched to Day Tab: referenceDate = $referenceDate');
                                      } else if (index == 1) {
                                        viewType = 'Week';
                                        referenceDate = now.subtract(
                                            Duration(days: now.weekday - 1));
                                        debugPrint(
                                            'Switched to Week Tab: referenceDate = $referenceDate');
                                      } else if (index == 2) {
                                        viewType = 'Month';
                                        referenceDate =
                                            DateTime(now.year, now.month);
                                        debugPrint(
                                            'Switched to Month Tab: referenceDate = $referenceDate');
                                      } else if (index == 3) {
                                        viewType = 'Year';
                                        referenceDate = DateTime(now.year);
                                        debugPrint(
                                            'Switched to Year Tab: referenceDate = $referenceDate');
                                      }
                                    });
                                  },
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
                                  tabs: const [
                                    Tab(text: 'Day'),
                                    Tab(text: 'Week'),
                                    Tab(text: 'Month'),
                                    Tab(text: 'Year'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: canMoveBack()
                                          ? () => moveReferenceDate(-1)
                                          : null,
                                      icon: const Icon(Icons.arrow_left),
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
                                      icon: const Icon(Icons.arrow_right),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TabBarView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: List.generate(4, (_) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: isBarChart
                                            ? buildBarChart(
                                                context, entries, viewType)
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
              child:
                  Text('No entries found yet.', style: TextStyle(fontSize: 16)),
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

    // filter by the selected range (Day, Week, Month, Year)
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

  String getBadgeForEntries(int totalEntries) {
    if (totalEntries == 0) return 'Grey'; // 0 entries, grey
    if (totalEntries >= 20) return 'Red'; // 20 or more entries, red
    if (totalEntries >= 15) return 'Purple'; // 15-19 entries, purple
    if (totalEntries >= 10) return 'Blue'; // 10-14 entries, blue
    if (totalEntries >= 5) return 'Green'; // 5-9 entries, green
    return 'Yellow'; // 1-4 entries, yellow
  }

  List<Entry> filterEntriesByViewType(List<Entry> entries, String viewType,
      {DateTime? selectedDate}) {
    final now = selectedDate ?? DateTime.now();
    List<Entry> filteredEntries = [];

    switch (viewType) {
      case 'Day':
        filteredEntries = entries.where((entry) {
          final ts = entry.timestamp;
          return ts.year == now.year &&
              ts.month == now.month &&
              ts.day == now.day;
        }).toList();
        break;

      case 'Week':
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filteredEntries = entries.where((entry) {
          final ts = entry.timestamp;
          return ts.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              ts.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        break;

      case 'Month':
        filteredEntries = entries.where((entry) {
          final ts = entry.timestamp;
          return ts.year == now.year && ts.month == now.month;
        }).toList();
        break;

      case 'Year':
        filteredEntries = entries.where((entry) {
          final ts = entry.timestamp;
          return ts.year == now.year;
        }).toList();
        break;
    }

    return filteredEntries;
  }

  Widget buildBarChart(
    BuildContext context,
    List<Entry> entries,
    String viewType,
  ) {
    final theme = Theme.of(context);
    final now = referenceDate;
    List<String> xLabels = [];
    List<int> yValues = [];

    final filteredEntries =
        filterEntriesByViewType(entries, viewType, selectedDate: referenceDate);

    // aggregation
    final Map<String, int> data = {};
    for (var entry in filteredEntries) {
      String key;
      switch (viewType) {
        case 'Day':
          key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
          break;
        case 'Week':
          key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
          break;
        case 'Month':
          key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
          break;
        case 'Year':
          key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
          break;
        default:
          key = '';
      }
      if (key.isNotEmpty) {
        data[key] = (data[key] ?? 0) + 1;
      }
    }

    void addBar(String label, int count) {
      xLabels.add(label);
      yValues.add(count);
    }

    // bars
    switch (viewType) {
      case 'Day':
        final today = DateFormat('yyyy-MM-dd').format(now);
        final count = data[today] ?? 0;
        addBar(DateFormat('dd/MM').format(now), count);
        break;

      case 'Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        for (int i = 0; i < 7; i++) {
          final date = startOfWeek.add(Duration(days: i));
          final key = DateFormat('yyyy-MM-dd').format(date);
          final label = DateFormat('E').format(date);
          addBar(label, data[key] ?? 0);
        }
        break;

      case 'Month':
        final firstOfMonth = DateTime(now.year, now.month, 1);
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final numWeeks = ((firstOfMonth.weekday - 1 + daysInMonth) / 7).ceil();

        for (int i = 0; i < numWeeks; i++) {
          int weekTotal = 0;
          for (int j = 0; j < 7; j++) {
            final day = firstOfMonth.add(Duration(days: i * 7 + j));
            if (day.month != now.month) break;
            final key = DateFormat('yyyy-MM-dd').format(day);
            weekTotal += data[key] ?? 0;
          }
          addBar('W${i + 1}', weekTotal);
        }
        break;

      case 'Year':
        for (int i = 1; i <= 12; i++) {
          int monthTotal = 0;
          final firstDay = DateTime(now.year, i, 1);
          final daysInMonth = DateTime(now.year, i + 1, 0).day;
          for (int d = 1; d <= daysInMonth; d++) {
            final day = DateTime(now.year, i, d);
            final key = DateFormat('yyyy-MM-dd').format(day);
            monthTotal += data[key] ?? 0;
          }
          addBar(DateFormat('MMM').format(firstDay), monthTotal);
        }
        break;

      default:
        return const Center(child: Text('Invalid view type'));
    }

    final maxY = yValues.isEmpty
        ? 5.0
        : (yValues.reduce((a, b) => a > b ? a : b)).toDouble() + 1.0;

    return LayoutBuilder(builder: (context, constraints) {
      const horizontalPadding = 16.0;
      final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
      final barWidth =
          availableWidth / (xLabels.length < 7 ? 7 : xLabels.length);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          height: constraints.maxHeight * 0.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= xLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(xLabels[index],
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                  ),
                  barGroups: List.generate(xLabels.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: yValues[index].toDouble(),
                          width: barWidth * 0.6,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    );
                  }),
                ),
              ),
              if (yValues.every((y) => y == 0))
                Text(
                  () {
                    switch (viewType) {
                      case 'Day':
                        return 'No entries for this day';
                      case 'Week':
                        return 'No entries for this week';
                      case 'Month':
                        return 'No entries for this month';
                      case 'Year':
                        return 'No entries for this year';
                      default:
                        return 'No data';
                    }
                  }(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildPieChart(
    BuildContext context,
    Map<String, int> badgeCountMap,
    String viewType,
  ) {
    final theme = Theme.of(context);
    final total = badgeCountMap.values.fold(0, (a, b) => a + b);

    debugPrint('--- Pie Chart Debug ---');
    debugPrint('Total entries: $total');
    debugPrint('Badge Count Map: $badgeCountMap');

    if (total == 0) {
      final greyColor = getColorForBadge('Grey');
      final noDataMessage = () {
        switch (viewType) {
          case 'Day':
            return 'No entries for this day';
          case 'Week':
            return 'No entries for this week';
          case 'Month':
            return 'No entries for this month';
          case 'Year':
            return 'No entries for this year';
          default:
            return 'No data';
        }
      }();

      return LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final chartSize = size * 0.8;

          return Center(
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: 1,
                          color: greyColor,
                          title: '',
                        ),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                  Text(
                    noDataMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final validEntries =
        badgeCountMap.entries.where((entry) => entry.value > 0).toList();

    debugPrint('Valid (non-zero) badge entries: ${validEntries.length}');
    for (final e in validEntries) {
      final percentage = (e.value / total) * 100;
      debugPrint(
        'Badge: ${e.key}, Count: ${e.value}, Percentage: ${percentage.toStringAsFixed(1)}%',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final chartSize = size * 0.8;

        return Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: PieChart(
              PieChartData(
                sections: validEntries.map((entry) {
                  final percentage = (entry.value / total) * 100;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: getColorForBadge(entry.key),
                    titleStyle: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  Color getColorForBadge(String badge) {
    switch (badge) {
      case 'Yellow':
        return const Color(0xFFECD438);
      case 'Green':
        return const Color(0xFF3EEC38);
      case 'Blue':
        return const Color(0xFF38C5EC);
      case 'Purple':
        return const Color(0xFFAD38EC);
      case 'Red':
        return const Color(0xFFEC383B);
      default:
        return const Color(0xFFE2E1DD);
    }
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
