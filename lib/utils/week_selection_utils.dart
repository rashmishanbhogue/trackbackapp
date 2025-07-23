// week_selection_utils.dart, to handle custom selection logic for week view in the ai metrics screen

DateTime? rangeStartDay;
DateTime? rangeEndDay;

// when a day is tapped, calculate the start and end of that week and store it
void updateWeekRange(DateTime selected) {
  final weekday = selected.weekday;
  rangeStartDay = selected.subtract(Duration(days: weekday - 1)); // monday
  rangeEndDay = selected.add(Duration(days: 7 - weekday)); // sunday
}

// check if a given day falls within the stored week range
bool isInWeekRange(DateTime day) {
  if (rangeStartDay == null || rangeEndDay == null) return false;
  return (day.isAtSameMomentAs(rangeStartDay!) ||
      day.isAtSameMomentAs(rangeEndDay!) ||
      (day.isAfter(rangeStartDay!) && day.isBefore(rangeEndDay!)));
}
