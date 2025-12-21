// trends_charts.dart, to handle the pie chart and bar graph builds

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/entry.dart';
import '../theme.dart';

// build a bar chart, presentational only with no state mutations
// x axis granularity depends upon viewtype
Widget buildBarChart(
  BuildContext context,
  List<Entry> entries,
  String viewType,
  DateTime referenceDate,
) {
  final theme = Theme.of(context);
  final now = referenceDate;
  // x axis labels (day/week/month/year)
  List<String> xLabels = [];
  // y axis values - entry counts
  List<int> yValues = [];

  // filter entries defensively to isolate chart logic from caller mistakes
  final filteredDates =
      filterEntriesByViewType(entries, viewType, selectedDate: referenceDate);

  // aggregate counts per calendar day
  final Map<String, int> data = {};
  for (var entry in filteredDates) {
    String key = DateFormat('yyyy-MM-dd').format(entry.timestamp);
    if (key.isNotEmpty) {
      data[key] = (data[key] ?? 0) + 1;
    }
  }

  // helper to keep x/y arrays in sync
  void addBar(String label, int count) {
    xLabels.add(label);
    yValues.add(count);
  }

  // generate bars based on selected tieme resolution
  switch (viewType) {
    case 'Day':
      // single bar for the selected day
      final today = DateFormat('yyyy-MM-dd').format(now);
      final count = data[today] ?? 0;
      addBar(DateFormat('dd/MM').format(now), count);
      break;
    case 'Week':
      // 7 bars, one per weekday (mon-sun)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        final label = DateFormat('E').format(date);
        addBar(label, data[key] ?? 0);
      }
      break;
    case 'Month':
      // 4 or 5 bars depending upon the weekcount for that month
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
      // one bar per month
      for (int i = 1; i <= 12; i++) {
        int monthTotal = 0;
        final firstDay = DateTime(now.year, i, 1);
        final daysInMonth = DateTime(now.year, i + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          final day = DateTime(now.year, i, d);
          final key = DateFormat('yyyy-MM-dd').format(day);
          monthTotal += data[key] ?? 0;
        }
        // single letter month labels to avoid overcrowding
        final label =
            DateFormat('MMM', 'en_US').format(firstDay)[0].toUpperCase();
        addBar(label, monthTotal);
      }
      break;
    default:
      return const Center(child: Text('Invalid view type'));
  }

  // determine chart scale dynamically
  final maxY = yValues.isEmpty
      ? 5.0
      : (yValues.reduce((a, b) => a > b ? a : b)).toDouble() + 1.0;

  return LayoutBuilder(
    builder: (context, constraints) {
      // calculate bar width dynamically to stay responsive
      const horizontalPadding = 16.0;
      final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
      final barWidth =
          availableWidth / (xLabels.length < 7 ? 7 : xLabels.length);

      // detect empty state
      final noData = yValues.every((y) => y == 0);

      return SizedBox(
        width: availableWidth,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.center,
                        maxY: maxY,
                        barTouchData: BarTouchData(enabled: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index >= xLabels.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(xLabels[index],
                                      style: theme.textTheme.bodyMedium),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.left,
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(xLabels.length, (index) {
                          final y = yValues[index].toDouble();
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: y,
                                width: barWidth * 0.6,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          );
                        }),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            // dashed max lines for quick visual comparison
                            if (!noData)
                              HorizontalLine(
                                y: yValues
                                    .reduce((a, b) => a > b ? a : b)
                                    .toDouble(),
                                color: AppTheme.iconDefaultDark,
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            // x axis dotted base line
                            HorizontalLine(
                              y: 0,
                              color: theme.brightness == Brightness.dark
                                  ? AppTheme.iconDefaultLight
                                  : AppTheme.iconDefaultDark,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // overlay dynamic empty state message
                    if (noData)
                      Align(
                        alignment: const Alignment(0, -0.4),
                        child: Text(
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
                          style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight),
                          textAlign: TextAlign.center,
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
  );
}

// doughnut pie chart for badge distribution
// used only when at least one badge has non zero count
Widget buildPieChart(
  BuildContext context,
  Map<String, int> badgeCountMap,
  String viewType,
  DateTime referenceDate,
) {
  final theme = Theme.of(context);
  final total = badgeCountMap.values.fold(0, (a, b) => a + b);

  // handle empty state explicitly to avoid misleading visuals
  if (total == 0) {
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
        final size = constraints.biggest.shortestSide;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 1,
                        color: theme.brightness == Brightness.dark
                            ? AppTheme.pieBackgroundDark
                            : AppTheme.pieBackgroundLight,
                        title: '',
                        radius: size / 2 - 30, // doughnut hole
                      ),
                    ],
                    centerSpaceRadius: 30,
                    sectionsSpace: 4,
                    centerSpaceColor: Colors.transparent,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    noDataMessage,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // only render sloces with non zero values
  final validEntries =
      badgeCountMap.entries.where((entry) => entry.value > 0).toList();

  return LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest.shortestSide;
      final pieRadius = size / 2 - 30; // doughnut hole

      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              sections: validEntries.map((entry) {
                final percentage = (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: getColorForBadge(entry.key),
                  radius: pieRadius, // section thickness
                  titleStyle: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryLight,
                    shadows: [
                      const Shadow(
                        offset: Offset(0, 0),
                        blurRadius: 3,
                        color: AppTheme.textDisabledLight,
                      ),
                    ],
                  ),
                );
              }).toList(),
              sectionsSpace: 4,
              centerSpaceRadius: 30,
              centerSpaceColor: Colors.transparent,
            ),
          ),
        ),
      );
    },
  );
}

// filter entries based on the active tiem resolution - both charts and metrics logic share this
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

// map entry count to badge category
String getBadgeForEntries(int totalEntries) {
  if (totalEntries == 0) return 'Grey'; // 0 entries, grey
  if (totalEntries >= 20) return 'Red'; // 20 or more entries, red
  if (totalEntries >= 15) return 'Purple'; // 15-19 entries, purple
  if (totalEntries >= 10) return 'Blue'; // 10-14 entries, blue
  if (totalEntries >= 5) return 'Green'; // 5-9 entries, green
  return 'Yellow'; // 1-4 entries, yellow
}

// resolve badge name to theme color
Color getColorForBadge(String badge) {
  switch (badge) {
    case 'Yellow':
      return AppTheme.badgeYellow; // yellow
    case 'Green':
      return AppTheme.badgeGreen; // green
    case 'Blue':
      return AppTheme.badgeBlue; // blue
    case 'Purple':
      return AppTheme.badgePurple; // purple
    case 'Red':
      return AppTheme.badgeRed; // red
    default:
      return AppTheme.badgeGrey; // grey
  }
}
