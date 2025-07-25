// week_selection_utils.dart, to handle custom selection logic for week view in the ai metrics screen

DateTime? rangeStartDay;
DateTime? rangeEndDay;
DateTime? selectedDay;

// when a day is tapped, calculate the start and end of that week and store it
DateTime updateWeekRange(DateTime selected) {
  final start = selected.subtract(Duration(days: selected.weekday - 1));
  final normalizedStart = DateTime(start.year, start.month, start.day);
  rangeStartDay = normalizedStart;
  rangeEndDay = normalizedStart.add(const Duration(days: 6));
  return normalizedStart;
}

// check if a given day falls within the stored week range
bool isInWeekRange(DateTime day) {
  if (rangeStartDay == null || rangeEndDay == null) return false;

  final d = DateTime(day.year, day.month, day.day);
  final start =
      DateTime(rangeStartDay!.year, rangeStartDay!.month, rangeStartDay!.day);
  final end = DateTime(rangeEndDay!.year, rangeEndDay!.month, rangeEndDay!.day);

  return !d.isBefore(start) && !d.isAfter(end); // inclusive range
}
