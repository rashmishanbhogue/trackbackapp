// time_utils.dart

String getTimeOfDayBlock(DateTime timestamp) {
  final hour = timestamp.hour;
  if (hour >= 0 && hour < 12)
    return "Morning";
  else if (hour >= 12 && hour < 16)
    return "Afternoon";
  else if (hour >= 16 && hour < 21)
    return "Evening";
  else
    return "Night";
}
