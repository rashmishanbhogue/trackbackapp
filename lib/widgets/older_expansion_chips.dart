// older_expansion_chips.dart, homescreen lazy load sliver for entries older than currentmonth (year - month - day)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../theme.dart';
import '../widgets/completed_entries_section.dart';
import '../utils/home_dialog_utils.dart';

class OlderExpansionSliver extends StatelessWidget {
  // {'2025': {'01': ['2025-01-02', '2025-01-05'], '02': [...]}, ...}
  final Map<String, Map<String, List<String>>> groupedbyYear;
  // actual entry payloads per date
  final Map<String, List<Entry>> dateEntries;
  // flat list of all dates used to derive stable indices
  final List<String> previousDates;

  // control whether a full year section is expanded
  final Map<String, bool> yearVisibility;
  // control whether a specific month inside a year is expanded
  final Map<String, bool> monthVisibility;

  // currently expadned chip (only one chip globally)
  final int? expandedChipIndex;
  // toggle expandeChipIndex in parent
  final Function(int?) onChipTap;

  // toggle visibility of an entire year section
  final Function(String year) onYearToggle;
  // toggle visibility of a month within a year
  final Function(String monthKey) onMonthToggle;

  // key used to scroll expanded tiles into view reliably
  final Map<String, GlobalKey> expansionTileKeys;
  // needed for delete confirmation dialog provider access
  final WidgetRef ref;

  final bool isDark;

  const OlderExpansionSliver({
    super.key,
    required this.groupedbyYear,
    required this.dateEntries,
    required this.previousDates,
    required this.yearVisibility,
    required this.monthVisibility,
    this.expandedChipIndex,
    required this.onChipTap,
    required this.onYearToggle,
    required this.onMonthToggle,
    required this.expansionTileKeys,
    required this.ref,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // currentdate to exclude already rendered current month (previous days section)
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final currentMonth = now.month;

    return SliverList(
        delegate:
            SliverChildListDelegate(groupedbyYear.entries.expand((yearEntry) {
      final year = yearEntry.key;
      final months = yearEntry.value;

      // ensure year visibility state exists
      yearVisibility.putIfAbsent(year, () => false);

      // build list for this year only
      final List<Widget> yearWidgets = [];

      // year header
      yearWidgets.add(
        TextButton(
          onPressed: () => onYearToggle(year),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  year,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  (yearVisibility[year] ?? false)
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color:
                      isDark ? AppTheme.textHintDark : AppTheme.textHintLight,
                ),
              ],
            ),
          ),
        ),
      );

      // if year is collapsed, stop - lazy loading
      if (!(yearVisibility[year] ?? false)) {
        return yearWidgets;
      }

      // build months only when the year is expanded
      yearWidgets.addAll(
        months.entries.expand((monthEntry) {
          final month = int.parse(monthEntry.key);
          final dates = monthEntry.value;

          // aggregate total count for month label
          final totalEntriesforMonth =
              dates.expand((date) => dateEntries[date] ?? []).length;

          // skip current month (rendered under previous days section)
          if (year == currentYear && month == currentMonth) {
            return <Widget>[];
          }

          // stable keu for month-level visibility
          final monthKey = '$year-${month.toString().padLeft(2, '0')}';
          monthVisibility.putIfAbsent(monthKey, () => false);

          final List<Widget> monthWidgets = [];

          // month header
          monthWidgets.add(
            TextButton(
              onPressed: () => onMonthToggle(monthKey),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${DateFormat('MMMM').format(DateTime(int.parse(year), month))} ($totalEntriesforMonth)',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppTheme.textHintDark
                            : AppTheme.textHintLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      (monthVisibility[monthKey] ?? false)
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: isDark
                          ? AppTheme.textHintDark
                          : AppTheme.textHintLight,
                    ),
                  ],
                ),
              ),
            ),
          );

          // if month is collapsed, do not build teh date chips
          if (!(monthVisibility[monthKey] ?? false)) {
            return monthWidgets;
          }

          // horizontal chips (scrollable dates)
          monthWidgets.add(
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: dates.map((date) {
                  // hashcode to avoid index collisions across months
                  final key = date.hashCode;
                  final isSelected = expandedChipIndex == key;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: RawChip(
                      label: Text(
                        DateFormat('dd').format(DateTime.parse(date)),
                        style: TextStyle(
                          color: isSelected
                              ? (isDark
                                  ? AppTheme.baseWhite
                                  : AppTheme.baseBlack)
                              : Colors.grey[600],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        // ensure only one chip is expanded globally
                        onChipTap(isSelected ? null : key);
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: AppTheme.weekHighlightDark,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : AppTheme.weekHighlightDark,
                          width: 1.2,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          );

          // expanded tile
          // resolve which date is currently expanded for this month
          final expandedDate = dates.firstWhere(
            (d) => expandedChipIndex == d.hashCode,
            orElse: () => '',
          );

          // render expanded entry list ony for the active date
          if (expandedDate.isNotEmpty) {
            monthWidgets.add(
              CompletedEntriesSection(
                date: expandedDate,
                entries: dateEntries[expandedDate] ?? [],
                isExpanded: true,
                onToggle: () => onChipTap(null),
                tileKey: expansionTileKeys.putIfAbsent(
                    expandedDate, () => GlobalKey()),
                colorIndex: expandedDate.hashCode,
                confirmDismiss: (direction) async {
                  return await showDeleteConfirmationDialog(
                    context,
                    expandedDate,
                    ref,
                  );
                },
              ),
            );
          }

          return monthWidgets;
        }),
      );

      return yearWidgets;
    }).toList()));
  }
}
