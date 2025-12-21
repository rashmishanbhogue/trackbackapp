// date_week_utils.dart, used for overlay date and week calendar display in the ai metrics screen

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/week_selection_utils.dart';
import '../utils/aimetrics_filter_utils.dart';
import '../theme.dart';
import '../screens/aimetrics_screen.dart';
import '../models/entry.dart';

// explicit chevron change due to table_calendar built-in limitations
Icon getChevronIcon(
    {required bool isLeft,
    required DateTime currentMonth,
    required DateTime firstMonth,
    required DateTime lastMonth,
    required bool isDark}) {
  final isAtLimit = isLeft
      ? currentMonth.year == firstMonth.year &&
          currentMonth.month == firstMonth.month
      : currentMonth.year == lastMonth.year &&
          currentMonth.month == lastMonth.month;

  final color = isAtLimit
      ? (isDark ? Colors.white24 : Colors.black26)
      : (isDark ? Colors.white70 : Colors.black54);

  return Icon(isLeft ? Icons.chevron_left : Icons.chevron_right,
      size: 20, color: color);
}

// dynamic header style using chevron change due to table_calendar built-in limitations
HeaderStyle getDynamicHeaderStyle(
    {required DateTime visibleMonth,
    required DateTime firstMonth,
    required DateTime lastMonth,
    required bool isDark}) {
  return HeaderStyle(
      formatButtonVisible: false,
      titleCentered: true,
      titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppTheme.textSecondaryDark
              : AppTheme.textSecondaryLight),
      leftChevronIcon: getChevronIcon(
          isLeft: true,
          currentMonth: visibleMonth,
          firstMonth: firstMonth,
          lastMonth: lastMonth,
          isDark: isDark),
      rightChevronIcon: getChevronIcon(
          isLeft: false,
          currentMonth: visibleMonth,
          firstMonth: firstMonth,
          lastMonth: lastMonth,
          isDark: isDark));
}

// build the day selection calendar for aimetrics
// handle disabled dates, future dates, visual feedback on invalid taps
Widget buildDayCalendar({
  required TimeFilter filter,
  required DateTime focusedDay,
  required DateTime? selectedDay,
  required Function(DateTime, DateTime) onDaySelected,
  required bool isDark,
  required void Function(void Function()) setState,
  required DateTime currentVisibleMonth,
  required Function(DateTime) onVisibleMonthChanged,
  required DateTime firstMonth,
  required DateTime lastMonth,
  required EntryRangeInfo entryInfo,
  required Function(DateTime day, Offset offset) onDisabledDayTap,
}) {
  final daysOfWeekStyle = isDark
      ? AppTheme.calendarDaysOfWeekDark
      : AppTheme.calendarDaysOfWeekLight;
  final calendarStyle =
      isDark ? AppTheme.calendarStyleDark : AppTheme.calendarStyleLight;

  // ensure focused day never leaves valid bounds
  DateTime clampFocusedDay(DateTime day, DateTime first, DateTime last) {
    if (day.isBefore(first)) return first;
    if (day.isAfter(last)) return last;
    return day;
  }

  return TableCalendar(
      key: ValueKey(
          "calendar-day-${currentVisibleMonth.year}-${currentVisibleMonth.month}"),
      rowHeight: 32,
      firstDay: firstMonth,
      lastDay: lastMonth,
      focusedDay: clampFocusedDay(focusedDay, firstMonth, lastMonth),
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      // disable days that have no entries
      enabledDayPredicate: (day) {
        final d = DateTime(day.year, day.month, day.day);
        return entryInfo.availableDays.isEmpty ||
            entryInfo.availableDays.contains(d);
      },
      onDaySelected: (pickedDay, focusedDay) {
        // normalise and propagate selection
        selectedDay = DateTime(pickedDay.year, pickedDay.month,
            pickedDay.day); // from aimetrics_filter_utils.dart
        onDaySelected(
            pickedDay, focusedDay); // still call the original callback
      },
      // onDaySelected: onDaySelected,
      headerStyle: getDynamicHeaderStyle(
          visibleMonth: currentVisibleMonth,
          firstMonth: firstMonth,
          lastMonth: lastMonth,
          isDark: isDark),
      daysOfWeekStyle: daysOfWeekStyle,
      calendarStyle: calendarStyle,
      // custom builders required to intercept taps on disabled days
      calendarBuilders: defaultCalendarBuilder(
          isDark, filter, entryInfo, setState, onDisabledDayTap),
      onPageChanged: (visibleMonth) {
        // setState(() {
        //   currentVisibleMonth = visibleMonth;
        // });
        onVisibleMonthChanged(visibleMonth);
      });
}

// custom calendar builders for day filter - allow disabled dates to still receive tap feedback
CalendarBuilders defaultCalendarBuilder(
  bool isDark,
  TimeFilter filter,
  EntryRangeInfo entryInfo,
  void Function(void Function()) setState,
  void Function(DateTime day, Offset offset) onDisabledTap,
) {
  return CalendarBuilders(
    defaultBuilder: (context, day, _) {
      final now = DateTime.now();
      final isFuture = day.isAfter(DateTime(now.year, now.month, now.day));
      // to handle the disabled date tap
      final isDisabled = entryInfo.availableDays.isNotEmpty &&
          !entryInfo.availableDays
              .contains(DateTime(day.year, day.month, day.day));

      if (isFuture || isDisabled) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            onDisabledTap(day, details.globalPosition);
          },
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.textDisabledDark
                    : AppTheme.textDisabledLight,
              ),
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

// build the week selection calendar
// uses per day enabling becaue tablecalendar has no concept of weeks
Widget buildWeekCalendar({
  required List<Entry> allEntries,
  required DateTime focusedWeek,
  required DateTime? selectedWeek,
  required void Function(DateTime selected, DateTime focused) onWeekSelected,
  required bool isDark,
  required CalendarStyle calendarStyle,
  required VoidCallback setStateOverlay,
  required DateTime currentVisibleMonth,
  required Function(DateTime) onVisibleMonthChanged,
  required void Function(void Function()) setState,
  required DateTime firstMonth,
  required DateTime lastMonth,
  required EntryRangeInfo entryInfo,
  required void Function(DateTime day, Offset offset) onDisabledWeekTap,
}) {
  final enabledDates = getEnabledDatesWithEntries(allEntries);

  DateTime clampFocusedWeek(DateTime? focus, DateTime first, DateTime last) {
    if (focus == null) return DateTime.now();

    if (focus.isBefore(first)) return first;
    if (focus.isAfter(last)) return last;

    return focus;
  }

  // debugPrint('focusedWeek: $focusedWeek');
  // debugPrint('entryInfo firstDate: ${entryInfo.firstDate}');
  // debugPrint('entryInfo lastDate: ${entryInfo.lastDate}');
  // debugPrint(
  //     'clamped: ${clampFocusedWeek(focusedWeek, getStartOfWeek(entryInfo.firstDate), getEndOfWeek(entryInfo.lastDate))}');

  return TableCalendar(
    key: ValueKey(
        "calendar-week-${currentVisibleMonth.year}-${currentVisibleMonth.month}-${selectedWeek?.toIso8601String()}"),
    rowHeight: 32,
    focusedDay: clampFocusedWeek(
      focusedWeek,
      getStartOfWeek(entryInfo.firstDate),
      getEndOfWeek(entryInfo.lastDate),
    ),
    currentDay: DateTime.now(),

    // enable only dates that belong to weeks with entries
    enabledDayPredicate: (day) {
      final normalized = DateTime(day.year, day.month, day.day);
      return enabledDates.contains(normalized);
    },
    onDaySelected: (selected, focused) {
      setState(() {
        final selectedNormalized =
            DateTime(selected.year, selected.month, selected.day);
        selectedWeek = selectedNormalized;
        focusedWeek = selectedNormalized;
        updateWeekRange(selectedNormalized);
      });

      setStateOverlay(); // rebuild the overlay
      onWeekSelected(selected, focused);
    },

    onPageChanged: (visibleMonth) {
      setState(() {
        currentVisibleMonth = visibleMonth;
      });
      onVisibleMonthChanged(visibleMonth);
    },
    headerStyle: getDynamicHeaderStyle(
        visibleMonth: currentVisibleMonth,
        firstMonth: firstMonth,
        lastMonth: lastMonth,
        isDark: isDark),
    daysOfWeekStyle: isDark
        ? AppTheme.calendarDaysOfWeekDark
        : AppTheme.calendarDaysOfWeekLight,
    calendarStyle: const CalendarStyle(
      selectedDecoration: BoxDecoration(),
      selectedTextStyle: TextStyle(color: Colors.transparent),
      todayDecoration: BoxDecoration(
        color: AppTheme.currentDotColor,
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    calendarBuilders: buildWeekCalendarBuilders(
        isDark, entryInfo, rangeStartDay, rangeEndDay, onDisabledWeekTap),
    firstDay: entryInfo.firstDate,
    lastDay: entryInfo.lastDate,
  );
}

// return true if a day lies within the selected week range
bool isInWeekRange(
    DateTime day, DateTime? rangeStartDay, DateTime? rangeEndDay) {
  if (rangeStartDay == null || rangeEndDay == null) return false;
  return !day.isBefore(rangeStartDay) &&
      day.isBefore(rangeEndDay.add(const Duration(days: 1)));
}

// render a connected pill filter style week range cell (period calendar inspired, mon-sun)
Widget buildWeekRangeCell(
  BuildContext context,
  DateTime day,
  bool isDark,
  DateTime? rangeStartDay,
  DateTime? rangeEndDay,
) {
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

// calendar builders for week selection - handles range rendering and disabled week taps
CalendarBuilders buildWeekCalendarBuilders(
  bool isDark,
  EntryRangeInfo entryInfo,
  DateTime? rangeStartDay,
  DateTime? rangeEndDay,
  void Function(DateTime day, Offset offset) onDisabledWeekTap,
) {
  return CalendarBuilders(defaultBuilder: (context, day, _) {
    if (isInWeekRange(day, rangeStartDay, rangeEndDay)) {
      return buildWeekRangeCell(
          context, day, isDark, rangeStartDay, rangeEndDay);
    }
    final now = DateTime.now();
    final isFuture = day.isAfter(DateTime(now.year, now.month, now.day));
    final isDisabled = entryInfo.availableDays.isNotEmpty &&
        !entryInfo.availableDays
            .contains(DateTime(day.year, day.month, day.day));

    if (isFuture || isDisabled) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          onDisabledWeekTap(day, details.globalPosition);
        },
        child: Center(
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
    return null;
  });
}

// utility helpers used across calendars
DateTime getStartOfWeek(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

DateTime getEndOfWeek(DateTime date) {
  return date.add(Duration(days: 7 - date.weekday));
}

// extract normalised calendar days that contain entries - used to determine which weeks are selectable
Set<DateTime> getEnabledDatesWithEntries(List<Entry> allEntries) {
  return allEntries.map((entry) {
    final ts = entry.timestamp;
    return DateTime(ts.year, ts.month, ts.day);
  }).toSet();
}
