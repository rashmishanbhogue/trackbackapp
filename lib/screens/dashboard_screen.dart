import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen> {
  String viewType =
      'Week'; // setting to week- can be day, week, month or year as default
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
        final end = start.add(Duration(days: 6));
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

    // map of date strings to entry counts
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
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: isBarChart
                  ? buildBarChart(context, dataMap)
                  : buildPieChart(context, dataMap),
            )
          : const Center(
              child: Text(
                'No entries found yet.',
                style: TextStyle(fontSize: 16),
              ),
            ),
    );
  }

  Widget buildBarChart(BuildContext context, Map<String, int> data) {
    final sortedKeys = data.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Entries Trend:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showBadgeLegend(context);
              },
              tooltip: 'View Badge Details',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1,
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
                    getTitlesWidget: (double value, meta) {
                      final index = value.toInt();
                      if (index >= sortedKeys.length)
                        return const SizedBox.shrink();
                      final date = DateFormat('dd/MM')
                          .format(DateTime.parse(sortedKeys[index]));
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          date,
                          style: const TextStyle(fontSize: 10),
                        ),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPieChart(BuildContext context, Map<String, int> data) {
    final theme = Theme.of(context);
    final groupedData = groupByBadge(data);
    final total = groupedData.values.fold<int>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Badge Distribution:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showBadgeLegend(context);
              },
              tooltip: 'View Badge Details',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            child: PieChart(
              PieChartData(
                sections: groupedData.entries
                    .where((entry) => entry.value > 0)
                    .map((entry) {
                  final percentage = total > 0
                      ? ((entry.value / total) * 100).toStringAsFixed(1)
                      : '0.0';
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '$percentage%',
                    color: getColorForBadge(entry.key),
                    titleStyle: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        )
                      ],
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // group entry counts into badge categories
  Map<String, int> groupByBadge(Map<String, int> data) {
    final badgeGroups = <String, int>{
      'Grey': 0,
      'Yellow': 0,
      'Green': 0,
      'Blue': 0,
      'Purple': 0,
      'Red': 0,
    };

    for (var count in data.values) {
      if (count == 0) {
        badgeGroups['Grey'] = badgeGroups['Grey']! + 1;
      } else if (count >= 20) {
        badgeGroups['Red'] = badgeGroups['Red']! + 1;
      } else if (count >= 15) {
        badgeGroups['Purple'] = badgeGroups['Purple']! + 1;
      } else if (count >= 10) {
        badgeGroups['Blue'] = badgeGroups['Blue']! + 1;
      } else if (count >= 5) {
        badgeGroups['Green'] = badgeGroups['Green']! + 1;
      } else {
        badgeGroups['Yellow'] = badgeGroups['Yellow']! + 1;
      }
    }

    return badgeGroups;
  }

  // map badge name to its assigned colour
  Color getColorForBadge(String badgeName) {
    switch (badgeName) {
      case 'Grey':
        return const Color(0xFFE2E1DD);
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
