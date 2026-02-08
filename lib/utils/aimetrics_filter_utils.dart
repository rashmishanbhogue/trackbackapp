// aimetrics_filter_utils.dart, to extract available dates, weeks, months and years from entries for filtering

import '../utils/aimetrics_category_utils.dart';
import '../utils/constants.dart';
import '../utils/week_selection_utils.dart';
import '../models/entry.dart';
import '../screens/aimetrics_section.dart';

// return all unique calendar days yyyy-mm-dd that have entries - used to enable/ disable selectable days in the day filter calendar
List<DateTime> getAvailableDates(List<Entry> entries) {
  return entries
      .map((entry) => DateTime(
          entry.timestamp.year, entry.timestamp.month, entry.timestamp.day))
      .toSet()
      .toList()
    ..sort((a, b) => a.compareTo(b));
}

// return all unique months that ppear in the entry set - used for month level filtering
List<int> getAvailableMonths(List<Entry> entries) {
  return entries.map((entry) => entry.timestamp.month).toSet().toList();
}

// return all unique years that appear in the entry set - used for year level filtering and navigation bounds
List<int> getAvailableYears(List<Entry> entries) {
  return entries.map((entry) => entry.timestamp.year).toSet().toList();
}

// reutrn unique weeks represented as 'yyyy-mm-dd' - used to mark which weeks are selectable in the week filter (mon-sun)
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

// core filter used by ai metrics
// filters based on the currently active tiemfilter selection (all/day/week/month/year) - drived by the overlay ui, no parameters
// intentionally depends upon the shared state (selectedday/rangestartday)
List<Entry> filterEntriesByViewTypeAi({
  required List<Entry> entries,
  required TimeFilter viewType,
  required DateTime referenceDate,
}) {
  return entries.where((entry) {
    final ts = entry.timestamp;

    switch (viewType) {
      case TimeFilter.day:
        if (selectedDay == null) return false;
        return ts.year == selectedDay!.year &&
            ts.month == selectedDay!.month &&
            ts.day == selectedDay!.day;

      case TimeFilter.week:
        if (rangeStartDay == null || rangeEndDay == null) return false;
        return !ts.isBefore(rangeStartDay!) && !ts.isAfter(rangeEndDay!);

      case TimeFilter.month:
        final isMatch =
            ts.year == referenceDate.year && ts.month == referenceDate.month;
        return isMatch;

      case TimeFilter.year:
        final isMatch = ts.year == referenceDate.year;
        return isMatch;

      default:
        return true; // timefilter.all
    }
  }).toList();
}

// resolve canonical referencedate for the currently active filter - single source of truth when applying filters
DateTime getReferenceDateForFilter({
  required TimeFilter filter,
  required DateTime selectedDay,
  required DateTime? selectedWeek,
  required DateTime selectedMonth,
  required DateTime selectedYear,
}) {
  switch (filter) {
    case TimeFilter.day:
      return selectedDay;
    case TimeFilter.week:
      return selectedWeek ?? DateTime.now();
    case TimeFilter.month:
      return selectedMonth;
    case TimeFilter.year:
      return selectedYear;
    default:
      return DateTime.now();
  }
}

// group entries into their broader ai categories
// ensures all standard 6 categories are present even if they contain zero entries (ui stability)
Map<String, List<Entry>> groupEntriesByLabel(List<Entry> entries) {
  final map = <String, List<Entry>>{};

  // prefill with empty lists for all standard categories
  for (final category in standardCategories) {
    map[category] = [];
  }

  for (final e in entries) {
    final label = e.label.trim().isEmpty ? 'Uncategorized' : e.label;
    final broader = getBroaderCategory(label);
    map.putIfAbsent(broader, () => []).add(e);
  }

  return map;
}

// immutable container describing the valid date range of all entries
// used to clamp calendar navigation and disable invalid selections
class EntryRangeInfo {
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> availableDays;
  final Set<String> availableWeeks;
  final Set<DateTime> availableMonths;
  final Set<int> availableYears;

  EntryRangeInfo(
      {required this.firstDate,
      required this.lastDate,
      required this.availableDays,
      required this.availableWeeks,
      required this.availableMonths,
      required this.availableYears});
}

// compute the full selectable range from all entries
// called once on load and reused across all filter overlays
EntryRangeInfo calculateEntryRangeInfo(List<Entry> entries) {
  // debugPrint(
  //     'before IF calculateEntryRangeInfo called with ${entries.length} entries');

  if (entries.isEmpty) {
    final now = DateTime.now();
    return EntryRangeInfo(
        firstDate: now,
        lastDate: now,
        availableDays: {},
        availableWeeks: {},
        availableMonths: {},
        availableYears: {});
  }
  // debugPrint(
  //     'after IF calculateEntryRangeInfo called with ${entries.length} entries');
  final sortedEntries = entries.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final firstDate = sortedEntries.first.timestamp;
  final lastDate = sortedEntries.last.timestamp;

  final availableDays = entries
      .map(
          (e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
      .toSet();

  final availableWeeks = entries.map((e) {
    final startOfWeek =
        e.timestamp.subtract(Duration(days: e.timestamp.weekday - 1));
    return "${startOfWeek.year}-${startOfWeek.month}-${startOfWeek.day}";
  }).toSet();

  final availableMonths = entries
      .map((e) => DateTime(e.timestamp.year, e.timestamp.month, 1))
      .toSet();

  final availableYears = entries.map((e) => e.timestamp.year).toSet();

  // debugPrint('after availableDays $availableDays');
  // debugPrint('after availableWeeks $availableWeeks');
  // debugPrint('after availableMonths $availableMonths');
  // debugPrint(
  //     "availableMonths: ${availableMonths.map((d) => "${d.year}-${d.month}").toSet()}");
  // debugPrint('after availableYears $availableYears');
  // debugPrint("availableYears: $availableYears");
  // debugPrint('firstDate: $firstDate');
  // debugPrint('lastDate: $lastDate');

  return EntryRangeInfo(
      firstDate: firstDate,
      lastDate: lastDate,
      availableDays: availableDays,
      availableWeeks: availableWeeks,
      availableMonths: availableMonths,
      availableYears: availableYears);
}

// determine whether backward navigation is allowed for a given view - prevents scrolling before the first recorded entry similar to the trends scroll
bool canMoveBack(DateTime ref, String viewType, EntryRangeInfo info) {
  switch (viewType) {
    case 'Day':
      return ref.isAfter(info.firstDate);
    case 'Week':
      final startOfWeek = ref.subtract(Duration(days: ref.weekday - 1));
      return startOfWeek.isAfter(info.firstDate);
    case 'Month':
      final startOfMonth = DateTime(ref.year, ref.month, 1);
      return startOfMonth.isAfter(info.firstDate);
    case 'Year':
      final startOfYear = DateTime(ref.year);
      return startOfYear.isAfter(info.firstDate);
    default:
      return false;
  }
}

// high level helper used by aimetricsscreen - applies selected filter and return entries grouped by category
Map<String, List<Entry>> getFilteredLabelEntries({
  required List<Entry> entries,
  required TimeFilter filter,
  required DateTime selectedDay,
  required DateTime? selectedWeek,
  required DateTime selectedMonth,
  required DateTime selectedYear,
}) {
  final referenceDate = getReferenceDateForFilter(
    filter: filter,
    selectedDay: selectedDay,
    selectedWeek: selectedWeek,
    selectedMonth: selectedMonth,
    selectedYear: selectedYear,
  );

  // debugPrint(" Inside getFilteredLabelEntries");
  // debugPrint("  Filter: $filter");
  // debugPrint("  selectedDay: $selectedDay");
  // debugPrint("  selectedWeek: $selectedWeek");
  // debugPrint("  selectedMonth: $selectedMonth");
  // debugPrint("  selectedYear: $selectedYear");

  // debugPrint('FILTER: $filter');
  // debugPrint('REFERENCE DATE: $referenceDate');
  // debugPrint('ENTRIES COUNT: ${entries.length}');

  // tapping all does not reset the filtering logic, despite being selected otherwise
  final filtered = filter == TimeFilter.all
      ? entries
      : filterEntriesByViewTypeAi(
          entries: entries,
          viewType: filter,
          referenceDate: referenceDate,
        );

  return groupEntriesByLabel(filtered);
}
