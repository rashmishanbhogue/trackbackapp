import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../providers/date_entries_provider.dart';
import '../utils/time_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen> {
  String viewType = 'Week';
  DateTime referenceDate = DateTime.now();
  bool isBarChart = true;

  DateTimeRange getRange(String viewType, DateTime reference) {
    switch (viewType) {
      case 'Day':
        return DateTimeRange(
          start: DateTime(reference.year, reference.month, reference.day),
          end: DateTime(
              reference.year, reference.month, reference.day, 23, 59, 59),
        );
      case 'Week':
        final weekday = reference.weekday;
        final start = reference.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return DateTimeRange(start: start, end: end);
      case 'Month':
        final start = DateTime(reference.year, reference.month, 1);
        final end = DateTime(reference.year, reference.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case 'Year':
        return DateTimeRange(
          start: DateTime(reference.year, 1, 1),
          end: DateTime(reference.year, 12, 31),
        );
      default:
        throw Exception('Invalid viewType');
    }
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
              future: calculateMetrics(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final metrics = snapshot.data!;
                final timeOfDayCounts = metrics['times'] as Map<String, int>;

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
                                : 'Time of Day Distribution:',
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
                          child: Column(
                            children: [
                              SizedBox(
                                width: 300,
                                child: TabBar(
                                  indicatorColor: Colors.transparent,
                                  indicator: UnderlineTabIndicator(
                                    borderSide: BorderSide(
                                      color: selectedColor,
                                      width: 3,
                                    ),
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
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: TabBarView(
                                        children: List.generate(4, (_) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: isBarChart
                                                  ? buildBarChart(
                                                      context, dataMap)
                                                  : buildTimeOfDayPieChart(
                                                      context, timeOfDayCounts),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Time of Day Distribution:',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8),
                                              ...timeOfDayCounts.entries
                                                  .map((e) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Text(
                                                      '${e.key} : ${e.value}',
                                                      style: const TextStyle(
                                                          fontSize: 16)),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
              child: Text('No entries found yet.',
                  style: TextStyle(fontSize: 16))),
    );
  }

  Future<Map<String, dynamic>> calculateMetrics() async {
    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    Map<String, int> timeOfDayCounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
    };

    for (final entry in allEntries) {
      final block = getTimeOfDayBlock(entry.timestamp);
      timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
    }

    return {'times': timeOfDayCounts, 'entries': {}};
  }

  Widget buildBarChart(BuildContext context, Map<String, int> data) {
    final sortedKeys = data.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = 16.0;
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        final targetBarCount = sortedKeys.length < 7 ? 7 : sortedKeys.length;
        final barWidth = availableWidth / targetBarCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: constraints.maxHeight * 0.8,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.values.isEmpty
                    ? 5
                    : (data.values.reduce((a, b) => a > b ? a : b).toDouble() +
                        1),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index >= sortedKeys.length)
                          return const SizedBox.shrink();
                        final date = DateFormat('dd/MM')
                            .format(DateTime.parse(sortedKeys[index]));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child:
                              Text(date, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 1),
                  ),
                ),
                barGroups: List.generate(sortedKeys.length, (index) {
                  final count = data[sortedKeys[index]]!;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        width: barWidth * 0.6,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildTimeOfDayPieChart(BuildContext context, Map<String, int> data) {
    final theme = Theme.of(context);
    final total = data.values.fold(0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final chartSize = size * 0.98;

        return Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: PieChart(
              PieChartData(
                sections: data.entries.map((entry) {
                  final total = data.values.fold(0, (a, b) => a + b);
                  final percentage = total > 0
                      ? ((entry.value / total) * 100).toStringAsFixed(1)
                      : '0.0';
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '$percentage%',
                    color: getColorForTimeOfDay(entry.key),
                    titleStyle: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Color getColorForTimeOfDay(String block) {
    switch (block) {
      case 'Morning':
        return Colors.orange.shade300;
      case 'Afternoon':
        return Colors.blue.shade300;
      case 'Evening':
        return Colors.purple.shade300;
      default:
        return Colors.grey;
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
                  '🚀 Earn Badges!',
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
                        'asset': 'assets/badges/badge_0.svg',
                        'label': '0 entries'
                      },
                      {
                        'asset': 'assets/badges/badge_1.svg',
                        'label': '1–4 entries'
                      },
                      {
                        'asset': 'assets/badges/badge_2.svg',
                        'label': '5–9 entries'
                      },
                      {
                        'asset': 'assets/badges/badge_3.svg',
                        'label': '10–14 entries'
                      },
                      {
                        'asset': 'assets/badges/badge_4.svg',
                        'label': '15–19 entries'
                      },
                      {
                        'asset': 'assets/badges/badge_5.svg',
                        'label': '20+ entries'
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
