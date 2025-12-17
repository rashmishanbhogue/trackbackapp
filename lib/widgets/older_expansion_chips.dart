// older_expansion_chips.dart, homescreen lazy load sliver for entries older than currentmonth

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../theme.dart';
import '../widgets/completed_entries_section.dart';
import '../utils/home_dialog_utils.dart';

class OlderExpansionSliver extends StatelessWidget {
  final Map<String, Map<String, List<String>>> groupedbyYear;
  final Map<String, List<Entry>> dateEntries;
  final List<String> previousDates;

  final Map<String, bool> yearVisibility;
  final Map<String, bool> monthVisibility;

  final int? expandedChipIndex;
  final Function(int?) onChipTap;

  final Function(String year) onYearToggle;
  final Function(String monthKey) onMonthToggle;

  final Map<String, GlobalKey> expansionTileKeys;
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
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final currentMonth = now.month;

    return SliverList(
        delegate:
            SliverChildListDelegate(groupedbyYear.entries.expand((yearEntry) {
      final year = yearEntry.key;
      final months = yearEntry.value;

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

      if (!(yearVisibility[year] ?? false)) {
        return yearWidgets;
      }

      yearWidgets.addAll(
        months.entries.expand((monthEntry) {
          final month = int.parse(monthEntry.key);
          final dates = monthEntry.value;

          final totalEntriesforMonth = dates
              .expand((date) => dateEntries[date] ?? [])
              .length; // get total entries for a month

          if (year == currentYear && month == currentMonth) {
            return <Widget>[];
          }

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

          if (!(monthVisibility[monthKey] ?? false)) {
            return monthWidgets;
          }

          // horizontal chips
          monthWidgets.add(
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: dates.map((date) {
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
          final expandedDate = dates.firstWhere(
            (d) => expandedChipIndex == d.hashCode,
            orElse: () => '',
          );

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
