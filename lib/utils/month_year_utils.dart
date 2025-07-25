// month_year_utils.dart, to handle the month and year view in the ai metrics screen

import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/ai_metrics_screen.dart';

// build the month selector used in ai metrics screen, similar to the table calendar style
Widget buildMonthView(
    {required TimeFilter filter,
    required DateTime focusedMonth,
    required DateTime? selectedMonth,
    required Function(DateTime, DateTime) onSelectedMonth,
    required bool isDark,
    required Set<DateTime> availableData}) {
  // return stateless monthview with all passed params
  return MonthView(
    filter: filter,
    focusedMonth: focusedMonth,
    selectedMonth: selectedMonth,
    onSelectedMonth: onSelectedMonth,
    isDark: isDark,
    availableData: availableData,
  );
}

class MonthView extends StatelessWidget {
  final TimeFilter filter;
  final DateTime focusedMonth;
  final DateTime? selectedMonth;
  final Function(DateTime, DateTime) onSelectedMonth;
  final bool isDark;
  final Set<DateTime> availableData;

  const MonthView({
    super.key,
    required this.filter,
    required this.focusedMonth,
    this.selectedMonth,
    required this.onSelectedMonth,
    required this.isDark,
    required this.availableData,
  });

  // single tile builder
  Widget buildMonthTile(BuildContext context, int monthIndex) {
    final now = DateTime.now();

    // check if the month is current for blue dot placement in the grid
    final isCurrent = now.month == monthIndex && now.year == focusedMonth.year;

    // check if the month is selected
    final isSelected = selectedMonth?.month == monthIndex;

    return GestureDetector(
      onTap: () {
        // trigger selection callback with selected month and current focus year
        final selected = DateTime(focusedMonth.year, monthIndex);
        onSelectedMonth(selected, focusedMonth);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.weekHighlightDark
              : (isDark ? AppTheme.surfaceHighDark : AppTheme.surfaceHighLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          // stack to center the month label text while allowing the precise placement of dot without affecting the label alignment
          alignment: Alignment.center,
          children: [
            // main month label
            Text(
              monthName(monthIndex),
              style: TextStyle(
                fontSize: isSelected ? 15 : 14,
                color: isSelected
                    ? AppTheme.baseWhite
                    : (isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight),
              ),
            ),
            // blue dot for current month
            if (isCurrent)
              // positioned to place the dot exactly at the bottom center
              const Positioned(
                bottom: 0,
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: AppTheme.currentDotColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // convert month index to shortname
  String monthName(int monthIndex) {
    const monthNameList = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // exception
    if (monthIndex < 1 || monthIndex > 12) {
      return 'Invalid';
    }

    // subtract 1 because list is 0-indexed but months are 1-indexed (jan = 1)
    return monthNameList[monthIndex - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // shrink column to fit its content instead of expanding vertically
      children: [
        // top row with chevron scroll and year label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                iconSize: 18,
                color: isDark
                    ? AppTheme.iconDefaultDark
                    : AppTheme.iconDefaultLight,
                onPressed: () {
                  // move back 1 year
                  onSelectedMonth(
                    focusedMonth.subtract(const Duration(days: 365)),
                    focusedMonth.subtract(const Duration(days: 365)),
                  );
                }),
            // show 'this year' if current year, else show year number
            if (focusedMonth.year == DateTime.now().year)
              Text(
                'This Year',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              )
            else
              Text(
                '${focusedMonth.year}',
                style: TextStyle(
                  fontSize: 14,
                  // fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            // disable if current year
            IconButton(
              icon: const Icon(Icons.chevron_right),
              iconSize: 18,
              color: (focusedMonth.year == DateTime.now().year)
                  ? (isDark ? AppTheme.greyDark : AppTheme.idleDark)
                  : (isDark
                      ? AppTheme.iconDefaultDark
                      : AppTheme.iconDefaultLight),
              onPressed: () {
                if (focusedMonth.year == DateTime.now().year) {
                  // do nothing
                  return;
                }

                onSelectedMonth(
                  focusedMonth.add(const Duration(days: 365)),
                  focusedMonth.add(const Duration(days: 365)),
                );
              },
            ),
          ]),
        ),
        // 12 month 4x3 grid
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5),
          itemBuilder: (context, index) {
            return buildMonthTile(context, index + 1); // 1-based month index
          },
        ),
        const SizedBox(
            height:
                8), // add space between the grid and ok button on the parent overlay
      ],
    );
  }
}

// build the year selector used in ai metrics screen, similar to the table calendar style
Widget buildYearView({
  required TimeFilter filter,
  required DateTime focusedYear,
  required DateTime? selectedYear,
  required Function(DateTime, DateTime) onSelectedYear,
  required bool isDark,
  required Set<DateTime> availableData,
  required Function(DateTime) onFocusedYearChanged,
}) {
  // return stateless yearview with all passed params
  return YearView(
    filter: filter,
    focusedYear: focusedYear,
    selectedYear: selectedYear,
    onSelectedYear: onSelectedYear,
    onFocusedYearChanged: onFocusedYearChanged,
    isDark: isDark,
    availableData: availableData,
  );
}

class YearView extends StatelessWidget {
  final TimeFilter filter;
  final DateTime focusedYear;
  final DateTime? selectedYear;
  final Function(DateTime, DateTime) onSelectedYear;
  final bool isDark;
  final Set<DateTime> availableData;
  final Function(DateTime newFocusedYear) onFocusedYearChanged;

  const YearView({
    super.key,
    required this.filter,
    required this.focusedYear,
    this.selectedYear,
    required this.onSelectedYear,
    required this.isDark,
    required this.availableData,
    required this.onFocusedYearChanged,
  });

  // build each year tile in the decade grid
  Widget buildYearTile(BuildContext context, int year) {
    final now = DateTime.now();
    final isCurrent = now.year == year;
    final isSelected = selectedYear?.year == year;
    final isDisabled = year > now.year;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              final selected = DateTime(year);
              onSelectedYear(selected, focusedYear);
            },
      child: Opacity(
        // fade and disable future years instead of not listing them
        opacity: isDisabled ? 0.4 : 1,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.weekHighlightDark
                : (isDark
                    ? AppTheme.surfaceHighDark
                    : AppTheme.surfaceHighLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            // stack to center the year label text while allowing the precise placement of dot without affecting the label alignment
            alignment: Alignment.center,
            children: [
              // main year label
              Text(
                '$year',
                style: TextStyle(
                  fontSize: isSelected ? 16 : 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.baseWhite
                      : (isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight),
                ),
              ),
              if (isCurrent)
                const Positioned(
                  bottom: 4,
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppTheme.currentDotColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decadeStart = (focusedYear.year ~/ 10) * 10;
    final decadeEnd = decadeStart + 9;
    final now = DateTime.now();

    final isCurrentDecade = decadeStart <= now.year && now.year <= decadeEnd;
    final labelText = isCurrentDecade ? 'This Decade' : '${decadeStart}s';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // decade scroll and label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                iconSize: 18,
                color: isDark
                    ? AppTheme.iconDefaultDark
                    : AppTheme.iconDefaultLight,
                onPressed: () {
                  final previousDecade = DateTime(focusedYear.year - 10);
                  onFocusedYearChanged(previousDecade);
                }),
            Text(
              labelText, // 'This Decade' or 2000s, 1990s, etc
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: 18,
                color: (focusedYear.year == DateTime.now().year)
                    ? (isDark ? AppTheme.greyDark : AppTheme.idleDark)
                    : (isDark
                        ? AppTheme.iconDefaultDark
                        : AppTheme.iconDefaultLight),
                onPressed: () {
                  final nextDecade = DateTime(focusedYear.year + 10);
                  if (focusedYear.year + 10 > DateTime.now().year) {
                    return;
                  }

                  onFocusedYearChanged(nextDecade);
                }),
          ]),
        ),
        // decade wise 5x2 grid
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6),
          itemBuilder: (context, index) {
            final year = decadeStart + index;
            return buildYearTile(context, year); // display years per decade
          },
        ),
        const SizedBox(
            height:
                8), // add space between the grid and ok button on the parent overlay
      ],
    );
  }
}
