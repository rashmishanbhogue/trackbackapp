String getTimeOfDayBlock(DateTime timestamp) {
  final hour = timestamp.hour;
  if (hour < 12)
    return "Morning";
  else if (hour < 17)
    return "Afternoon";
  else
    return "Evening";
}
