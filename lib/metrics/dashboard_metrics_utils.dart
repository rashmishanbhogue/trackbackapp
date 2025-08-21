// dashboard_metrics_utils.dart, to handle the logic for metrics and badge calculations

import 'package:intl/intl.dart';
import '../metrics/dashboard_charts.dart';
import '../utils/time_utils.dart';
import '../models/entry.dart';

Future<Map<String, dynamic>> calculateMetrics(
  List<Entry> allEntries,
  String viewType, {
  DateTime? selectedDate,
}) async {
  final filteredEntries =
      filterEntriesByViewType(allEntries, viewType, selectedDate: selectedDate);

  Map<String, int> timeOfDayCounts = {
    'Morning': 0,
    'Afternoon': 0,
    'Evening': 0,
    'Night': 0,
  };

  for (final entry in filteredEntries) {
    final block = getTimeOfDayBlock(entry.timestamp);
    timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
  }

  return {
    'times': timeOfDayCounts,
    'entries': filteredEntries,
  };
}

Map<String, int> buildBadgeCountMap(
  List<Entry> entries,
  String viewType, {
  DateTime? selectedDate,
}) {
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
        final weekStart = DateTime(entry.timestamp.year, entry.timestamp.month,
                entry.timestamp.day)
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

  final filteredEntries =
      filterEntriesByViewType(entries, viewType, selectedDate: selectedDate);
  if (filteredEntries.isEmpty) return badgeCountMap;

  Map<String, List<Entry>> entriesGroupedByDay = {};
  for (final entry in filteredEntries) {
    final dayKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);
    entriesGroupedByDay.putIfAbsent(dayKey, () => []).add(entry);
  }

  for (final group in entriesGroupedByDay.values) {
    final count = group.length;
    final badge = getBadgeForEntries(count);
    badgeCountMap[badge] = (badgeCountMap[badge] ?? 0) + 1;
  }

  return badgeCountMap;
}

DateTime getFirstEntryDate(List<Entry> allEntries) {
  if (allEntries.isEmpty) return DateTime.now();
  return allEntries
      .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b)
      .timestamp;
}

// lazy load - compute metrics in background isolate
// isolate friendly with simple map/list input and simple map/list return
Map<String, dynamic> computeMetricsForAllViews(Map<String, dynamic> args) {
  final List<String> timeStampStrings =
      List<String>.from(args['timestamps'] ?? <String>[]);
  final List<String> viewTypes =
      List<String>.from(args['viewTypes'] ?? ['Day', 'Week', 'Month', 'Year']);
  final selectedDateIso = args['selectedDate'] as String?;
  final DateTime selectedDate = selectedDateIso != null
      ? DateTime.parse(selectedDateIso)
      : DateTime.now();

  // reconstruct DateTime list
  final dates = timeStampStrings.map((s) => DateTime.parse(s)).toList();

  final Map<String, dynamic> result = {};

  for (final view in viewTypes) {
    final filtered =
        filterDatesByViewType(dates, view, selectedDate: selectedDate);

    // times of day counts using same logic as original (use time_utils.getTimeOfDayBlock)
    Map<String, int> timeOfDayCounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Night': 0,
    };
    for (final dt in filtered) {
      final block = getTimeOfDayBlock(dt);
      timeOfDayCounts[block] = (timeOfDayCounts[block] ?? 0) + 1;
    }

    // badge counts (grouped by day/week/month/year depending on view)
    final badgeCountMap = calculateBadgeCountFromDates(filtered, view,
        selectedDate: selectedDate);

    // entries -> return only ISO timestamps (serializable)
    final entriesIso = filtered.map((d) => d.toIso8601String()).toList();
    result[view] = {
      'times': timeOfDayCounts,
      'entries': entriesIso,
      'badgeCountMap': badgeCountMap,
    };
  }

  return result;
}

Map<String, dynamic> computeMetricsForSingleView(Map<String, dynamic> args) {
  args['viewTypes'] = [args['viewType'] as String];
  final all = computeMetricsForAllViews(args);
  return all[args['viewType']] as Map<String, dynamic>;
}

// lazy: filter dates by view type (isolate-friendly)
List<DateTime> filterDatesByViewType(List<DateTime> dates, String viewType,
    {DateTime? selectedDate}) {
  final now = selectedDate ?? DateTime.now();
  List<DateTime> filtered = [];

  switch (viewType) {
    case 'Day':
      filtered = dates.where((ts) {
        return ts.year == now.year &&
            ts.month == now.month &&
            ts.day == now.day;
      }).toList();
      break;

    case 'Week':
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      filtered = dates.where((ts) {
        return ts.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            ts.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
      break;

    case 'Month':
      filtered = dates.where((ts) {
        return ts.year == now.year && ts.month == now.month;
      }).toList();
      break;

    case 'Year':
      filtered = dates.where((ts) {
        return ts.year == now.year;
      }).toList();
      break;
  }

  return filtered;
}

// lazy: compute badge counts from a list of timestamps (isolate-friendly)
Map<String, int> calculateBadgeCountFromDates(
    List<DateTime> dates, String viewType,
    {DateTime? selectedDate}) {
  Map<String, List<DateTime>> grouped = {};

  for (final dt in dates) {
    String key;
    switch (viewType) {
      case 'Day':
        key = DateFormat('yyyy-MM-dd').format(dt);
        break;
      case 'Week':
        final weekStart = DateTime(dt.year, dt.month, dt.day)
            .subtract(Duration(days: dt.weekday - 1));
        key = DateFormat('yyyy-MM-dd').format(weekStart);
        break;
      case 'Month':
        key = DateFormat('yyyy-MM').format(dt);
        break;
      case 'Year':
        key = DateFormat('yyyy').format(dt);
        break;
      default:
        key = DateFormat('yyyy-MM-dd').format(dt);
    }
    grouped.putIfAbsent(key, () => []).add(dt);
  }

  Map<String, int> badgeCountMap = {
    'Yellow': 0,
    'Green': 0,
    'Blue': 0,
    'Purple': 0,
    'Red': 0,
    'Grey': 0,
  };

  for (final group in grouped.values) {
    final int totalEntries = group.length;
    final String badge = getBadgeForEntries(totalEntries);
    badgeCountMap[badge] = (badgeCountMap[badge] ?? 0) + 1;
  }

  return badgeCountMap;
}
