// calendar_utils.dart, used for overlay calendar display in the ai metrics screen

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/week_selection_utils.dart';
import '../theme.dart';
import '../screens/ai_metrics_screen.dart';

bool isAtMinMonth(DateTime visible, DateTime first) =>
    visible.year == first.year && visible.month == first.month;

bool isAtMaxMonth(DateTime visible, DateTime last) =>
    visible.year == last.year && visible.month == last.month;

Icon getChevronIcon(bool isLeft, DateTime currentMonth, bool isDark) {
  final firstMonth = DateTime(2020, 1);
  final lastMonth = DateTime.now();

  final isAtLimit = isLeft
      ? currentMonth.year == firstMonth.year &&
          currentMonth.month == firstMonth.month
      : currentMonth.year == lastMonth.year &&
          currentMonth.month == lastMonth.month;

  final color = isAtLimit
      ? (isDark ? Colors.white24 : Colors.black26)
      : (isDark ? Colors.white70 : Colors.black54);

  return Icon(
    isLeft ? Icons.chevron_left : Icons.chevron_right,
    size: 20,
    color: color,
  );
}

Widget buildDayCalendar({
  required TimeFilter filter,
  required DateTime focusedDay,
  required DateTime? selectedDay,
  required Function(DateTime, DateTime) onDaySelected,
  required bool isDark,
  required void Function(void Function()) setState,
  required DateTime currentVisibleMonth,
  required Function(DateTime) onVisibleMonthChanged,
}) {
  final firstDay = DateTime(2020);
  final lastDay = DateTime.now();

  final daysOfWeekStyle = isDark
      ? AppTheme.calendarDaysOfWeekDark
      : AppTheme.calendarDaysOfWeekLight;
  final calendarStyle =
      isDark ? AppTheme.calendarStyleDark : AppTheme.calendarStyleLight;

  return TableCalendar(
    key: ValueKey(
        "calendar-day-${currentVisibleMonth.year}-${currentVisibleMonth.month}"),
    rowHeight: 32,
    firstDay: DateTime(2020),
    lastDay: DateTime.now(),
    focusedDay: focusedDay,
    selectedDayPredicate: (day) => isSameDay(day, selectedDay),
    onDaySelected: onDaySelected,
    headerStyle: getDynamicHeaderStyle(currentVisibleMonth, isDark),
    daysOfWeekStyle: daysOfWeekStyle,
    calendarStyle: calendarStyle,
    calendarBuilders: defaultCalendarBuilder(isDark, filter),
    onPageChanged: (visibleMonth) => onVisibleMonthChanged(visibleMonth),
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
              color: isDark
                  ? AppTheme.textDisabledDark
                  : AppTheme.textDisabledLight,
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
          color: AppTheme.weekHighlightDark,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: AppTheme.baseWhite,
            fontSize: 14,
          ),
        ),
      );
    },
    todayBuilder: (context, day, _) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: const BoxDecoration(
          color: AppTheme.currentDotColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: AppTheme.baseWhite,
            fontSize: 14,
          ),
        ),
      );
    },
  );
}

Widget buildWeekCalendar({
  required DateTime focusedWeek,
  required DateTime? selectedWeek,
  required void Function(DateTime selected, DateTime focused) onWeekSelected,
  required bool isDark,
  required CalendarStyle calendarStyle,
  required VoidCallback setStateOverlay,
  required DateTime currentVisibleMonth,
  required Function(DateTime) onVisibleMonthChanged,
  required void Function(void Function()) setState,
}) {
  final firstDay = DateTime(2020, 1, 1);
  final lastDay = DateTime.now().add(const Duration(days: 6));

  return TableCalendar(
    key: ValueKey(
        "calendar-day-${currentVisibleMonth.year}-${currentVisibleMonth.month}"),
    rowHeight: 32,
    focusedDay: focusedWeek,
    selectedDayPredicate: (day) => isSameDay(day, rangeStartDay),
    onDaySelected: (selected, focused) {
      setState(() {
        final selectedNormalized =
            DateTime(selected.year, selected.month, selected.day);
        selectedDay = updateWeekRange(selectedNormalized);
        focusedWeek = selectedNormalized;
      });

      setStateOverlay();
      onWeekSelected(selected, focused);
    },
    onPageChanged: onVisibleMonthChanged,
    headerStyle: getDynamicHeaderStyle(currentVisibleMonth, isDark),
    daysOfWeekStyle: isDark
        ? AppTheme.calendarDaysOfWeekDark
        : AppTheme.calendarDaysOfWeekLight,
    calendarStyle: calendarStyle,
    calendarBuilders: buildWeekCalendarBuilders(isDark),
    firstDay: firstDay,
    lastDay: lastDay,
  );
}

Widget? buildWeekRangeCell(BuildContext context, DateTime day, bool isDark) {
  if (!isInWeekRange(day)) return null;

  final isStart = isSameDay(day, rangeStartDay);
  final isEnd = isSameDay(day, rangeEndDay);

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.weekHighlightDark,
      borderRadius: BorderRadius.horizontal(
        left: isStart ? const Radius.circular(16) : Radius.zero,
        right: isEnd ? const Radius.circular(16) : Radius.zero,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: const TextStyle(
        color: AppTheme.baseWhite,
        fontSize: 14,
      ),
    ),
  );
}

CalendarBuilders buildWeekCalendarBuilders(bool isDark) {
  return CalendarBuilders(
    defaultBuilder: (context, day, _) =>
        buildWeekRangeCell(context, day, isDark),
    selectedBuilder: (context, day, _) =>
        buildWeekRangeCell(context, day, isDark) ??
        Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
              fontSize: 14,
            ),
          ),
        ),
  );
}

HeaderStyle getDynamicHeaderStyle(DateTime visibleMonth, bool isDark) {
  return HeaderStyle(
    formatButtonVisible: false,
    titleCentered: true,
    titleTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
    ),
    leftChevronIcon: getChevronIcon(true, visibleMonth, isDark),
    rightChevronIcon: getChevronIcon(false, visibleMonth, isDark),
  );
}
