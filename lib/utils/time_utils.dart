// time_utils.dart, to define time blocks for the time of day distribution

String getTimeOfDayBlock(DateTime timestamp) {
  final hour = timestamp.hour;
  if (hour >= 0 && hour < 12) {
    return "Morning";
  } else if (hour >= 12 && hour < 16) {
    return "Afternoon";
  } else if (hour >= 16 && hour < 21) {
    return "Evening";
  } else {
    return "Night";
  }
}
