// week_selection_utils.dart, to handle custom selection logic for week view in the ai metrics screen

import 'package:flutter/material.dart';

// start of the currently selected week (mon)
DateTime? rangeStartDay;
// end of the currently selected week (sun)
DateTime? rangeEndDay;
// last explicitly selected day (used by day/week filters)
DateTime? selectedDay;

// when a day is tapped, calculate the start and end of that week and store it
// DateTime updateWeekRange(DateTime selected) {
//   final start = selected.subtract(Duration(days: selected.weekday - 1));
//   final normalizedStart = DateTime(start.year, start.month, start.day);
//   rangeStartDay = normalizedStart;
//   rangeEndDay = normalizedStart.add(const Duration(days: 6));
//   return normalizedStart;
// }

// calculate and store the mon-sun range for a tapped date - return normalised mon start date
DateTime updateWeekRange(DateTime selected) {
  // treat sunday (weekday == 7) as belonging to the previous mon - sun week
  final adjustedSelected = selected.weekday == 7
      ? selected.subtract(const Duration(days: 6))
      : selected.subtract(Duration(days: selected.weekday - 1));

  // normalise to midnight to avoid time comparison bugs
  final normalizedStart = DateTime(
      adjustedSelected.year, adjustedSelected.month, adjustedSelected.day);
  rangeStartDay = normalizedStart;
  rangeEndDay = normalizedStart.add(const Duration(days: 6));

  debugPrint('[WEEK SELECTED] rangeStartDay: $rangeStartDay');
  debugPrint('[WEEK SELECTED] rangeEndDay  : $rangeEndDay');

  return normalizedStart;
}

// check if a given day falls within the stored week range
bool isInWeekRange(DateTime day) {
  if (rangeStartDay == null || rangeEndDay == null) return false;

  final d = DateTime(day.year, day.month, day.day);
  final start =
      DateTime(rangeStartDay!.year, rangeStartDay!.month, rangeStartDay!.day);
  final end = DateTime(rangeEndDay!.year, rangeEndDay!.month, rangeEndDay!.day);

  return !d.isBefore(start) &&
      !d.isAfter(end); // inclusive date only range comparison
}
