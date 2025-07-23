// calendar_utils.dart, used for overlay calendar display in the ai metrics screen

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/week_selection_utils.dart';
import '../theme.dart';
import '../screens/ai_metrics_screen.dart';

Widget buildDayCalendar({
  required TimeFilter filter,
  required DateTime focusedDay,
  required DateTime? selectedDay,
  required Function(DateTime, DateTime) onDaySelected,
  required bool isDark,
}) {
  final headerStyle =
      isDark ? AppTheme.calendarHeaderDark : AppTheme.calendarHeaderLight;
  final daysOfWeekStyle = isDark
      ? AppTheme.calendarDaysOfWeekDark
      : AppTheme.calendarDaysOfWeekLight;
  final calendarStyle =
      isDark ? AppTheme.calendarStyleDark : AppTheme.calendarStyleLight;

  return TableCalendar(
    rowHeight: 32,
    firstDay: DateTime(2020),
    lastDay: DateTime.now(),
    focusedDay: focusedDay,
    selectedDayPredicate: (day) => isSameDay(day, selectedDay),
    onDaySelected: onDaySelected,
    headerStyle: headerStyle,
    daysOfWeekStyle: daysOfWeekStyle,
    calendarStyle: calendarStyle,
    calendarBuilders: defaultCalendarBuilder(isDark, filter),
  );
}

CalendarBuilders defaultCalendarBuilder(bool isDark, TimeFilter filter) {
  return CalendarBuilders(
    defaultBuilder: (context, day, _) {
      final now = DateTime.now();
      final isFuture = day.isAfter(DateTime(now.year, now.month, now.day));

      if (isFuture) {
        return Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        );
      }

      return null;
    },
    selectedBuilder: (context, day, _) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      );
    },
    todayBuilder: (context, day, _) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: const BoxDecoration(
          color: Colors.lightBlueAccent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      );
    },
  );
}

Widget buildWeekCalendar({
  required DateTime focusedDay,
  required DateTime? selectedDay,
  required void Function(DateTime selected, DateTime focused) onDaySelected,
  required bool isDark,
  required CalendarStyle calendarStyle,
  required VoidCallback setStateOverlay,
  required void Function(void Function()) setState,
}) {
  return TableCalendar(
    rowHeight: 32,
    firstDay: DateTime(2020),
    lastDay: DateTime.now(),
    focusedDay: focusedDay,
    selectedDayPredicate: (day) => false,
    onDaySelected: (selected, focused) {
      setState(() {
        selectedDay = selected;
        focusedDay = focused;

        updateWeekRange(selected); // use helper
      });
      setStateOverlay();
      onDaySelected(selected, focused);
    },
    headerStyle:
        isDark ? AppTheme.calendarHeaderDark : AppTheme.calendarHeaderLight,
    daysOfWeekStyle: isDark
        ? AppTheme.calendarDaysOfWeekDark
        : AppTheme.calendarDaysOfWeekLight,
    calendarStyle: calendarStyle,
    calendarBuilders: CalendarBuilders(defaultBuilder: (context, day, _) {
      return buildWeekRangeCell(context, day, isDark);
    }),
  );
}

Widget? buildWeekRangeCell(BuildContext context, DateTime day, bool isDark) {
  if (!isInWeekRange(day)) return null;

  final isStart = isSameDay(day, rangeStartDay);
  final isEnd = isSameDay(day, rangeEndDay);

  final now = DateTime.now();
  now.subtract(Duration(days: now.weekday - 1)); // monday
  now.add(Duration(days: 7 - now.weekday));

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      color: Colors.orangeAccent,
      borderRadius: BorderRadius.horizontal(
        left: isStart ? const Radius.circular(16) : Radius.zero,
        right: isEnd ? const Radius.circular(16) : Radius.zero,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),
  );
}
