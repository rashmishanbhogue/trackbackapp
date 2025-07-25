// expandable_chips.dart, app's collapsible chips used in homescreen and aimetricsscreen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/entry.dart';
import '../screens/home_screen.dart';
import '../theme.dart';

// expansiontiles for homescreen
class HomeExpansionTiles extends StatelessWidget {
  // {'2025-07': [dates...], '2025-06': [dates...]}
  final Map<String, List<String>> groupedByMonth;
  // actual entries for a given date {'2025-07-24': [Entry, Entry]}
  final Map<String, List<Entry>> dateEntries;
  // index based tracking of each tile
  // expansiontile on its own doesnt expose expansion state directly
  final List<String> previousDates;
  // map to control whether a prev month is shown or not - current month is always visible
  final Map<String, bool> monthVisibility;
  // which tile is expanded - only one at a time, null = none expanded
  final int? expandedChipIndex;
  // tap handler to set expandedchipindex in parent
  final Function(int?) onChipTap;
  // passed to dismissable confirm callback - trigger deletion after confirmation
  final Function(String date) onDelete;
  // toggle visibility of a month (for past months) when user taps header
  final Function(String monthKey) onMonthToggle;
  // for scroll-to behaviour - each expansiontile gets its own globalkey
  final Map<String, GlobalKey> expansionTileKeys;
  // current month string - only month shown by default
  final String currentMonth;
  // widgetref needed for dialog callback
  final WidgetRef ref;

  const HomeExpansionTiles({
    super.key,
    required this.groupedByMonth,
    required this.dateEntries,
    required this.previousDates,
    required this.monthVisibility,
    this.expandedChipIndex,
    required this.onChipTap,
    required this.onDelete,
    required this.onMonthToggle,
    required this.expansionTileKeys,
    required this.currentMonth,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        groupedByMonth.entries.expand((entry) {
          // section - one month worth of chips
          final isCurrent = entry.key == currentMonth;

          // past months - show month header with toggle
          final monthYear =
              DateFormat('MMMM yyyy').format(DateTime.parse('${entry.key}-01'));

          final List<Widget> widgets = [];

          if (!isCurrent) {
            // init visibility state if not already present
            monthVisibility.putIfAbsent(entry.key, () => false);

            // month toggle button (past months only)
            widgets.add(
              TextButton(
                onPressed: () {
                  onMonthToggle(entry.key);
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthYear,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // only show ocntents if this month is current or manually toggled open
          final shouldShow = isCurrent || (monthVisibility[entry.key] ?? false);

          if (shouldShow) {
            widgets.addAll(entry.value.map((date) {
              final formattedDate =
                  DateFormat('dd-MMM-yyyy').format(DateTime.parse(date));
              final tileKey =
                  expansionTileKeys.putIfAbsent(date, () => GlobalKey());
              // figure out expanded state
              final index = previousDates.indexOf(date);
              final count = dateEntries[date]?.length ?? 0;
              final isExpanded = expandedChipIndex == index;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Dismissible(
                  key: Key(date),
                  direction: DismissDirection.endToStart,
                  background: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.iconDeleteContent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child:
                          const Icon(Icons.delete, color: AppTheme.baseWhite),
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDeleteConfirmationDialog(
                        context, date, ref);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      // outer container for focused tile border effect
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.getHomeTileColor(index, context),
                          borderRadius: BorderRadius.circular(20),
                          border: isExpanded
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1,
                                )
                              : null),
                      child: Column(
                        key: tileKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // header - date + badge
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? AppTheme.textPrimaryLight
                                        : AppTheme.textPrimaryDark,
                                  ),
                                ),
                                const Expanded(child: SizedBox(width: 0)),
                                buildBadge(count),
                              ],
                            ),
                            onTap: () {
                              onChipTap(isExpanded ? null : index);
                              if (!isExpanded) {
                                // scroll to it if needed (only when expanding)
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  // get the build context of the expanded tiel via its key
                                  final ctx = tileKey.currentContext;
                                  if (ctx != null) {
                                    // wait till next frame so layout is complete
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      final ctx = tileKey.currentContext;
                                      if (ctx != null) {
                                        // get the tiles position on screen
                                        final renderBox =
                                            ctx.findRenderObject() as RenderBox;
                                        final position = renderBox
                                            .localToGlobal(Offset.zero)
                                            .dy;
                                        final screenHeight =
                                            MediaQuery.of(ctx).size.height;
                                        // check if tile is pushed too far down
                                        final isTooLow =
                                            position > screenHeight * 0.6;

                                        // scroll to make tile visible (middle ish of the screen)
                                        Scrollable.ensureVisible(
                                          ctx,
                                          duration:
                                              const Duration(milliseconds: 400),
                                          alignment: isTooLow ? 0.05 : 0.1,
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    });
                                  }
                                });
                              }
                            },
                          ),
                          // list of entries for that day
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            // animate open/close when tile expands or collapses
                            child: isExpanded
                                ? Column(
                                    children:
                                        (dateEntries[date] ?? []).map((entry) {
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          // collapse tile when user taps inside
                                          onChipTap(null);
                                        },
                                        child: ListTile(
                                          title: Text(
                                            entry.text,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const SizedBox
                                    .shrink(), // hidden when collapsed
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }));
          }

          return widgets;
        }).toList(),
      ),
    );
  }
}

// expansiontiles for aimetricsscreen
class AiMetricsExpansionTiles extends StatelessWidget {
  // map of category label to list of entries for that category {'Wellbeing': [Entry1, Entry2], 'Idle': [Entry3, Entry4]}
  final Map<String, List<Entry>> labelToEntries;
  // currently expanded category (only one at a time) - null if none expanded
  final String? expandedCategory;
  // whether refresh spinner should be shown
  final bool isRefreshing;
  // callback when the chip is tapped (expand/ collapse)
  final Function(String? category) onTap;
  final bool isDark;
  // map to track each tile's globalkey (for scroll position)
  final Map<String, GlobalKey> categoryKeys;

  const AiMetricsExpansionTiles(
      {super.key,
      required this.labelToEntries,
      this.expandedCategory,
      required this.isRefreshing,
      required this.onTap,
      required this.isDark,
      required this.categoryKeys});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: buildTiles(context),
    );
  }

  List<Widget> buildTiles(BuildContext context) {
    // filter and order categories based on predefined lsit of 6, not alphabetical, not by count
    final sortedCategories = standardCategories
        .where((category) => labelToEntries.containsKey(category))
        .toList();

    return sortedCategories.map((category) {
      // get the list of entries for this category/ an empty list if none exist
      final entries = labelToEntries[category] ?? [];
      // newest entry first
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      // number of entries in this category
      final count = entries.length;
      // check if this category is currently expanded
      final isExpanded = expandedCategory == category;
      // retrieve the globalkey for this category tile (to scroll into view)
      final tileKey = categoryKeys[category];

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              key: tileKey,
              onTap: () {
                // toggle expansion state on tap
                onTap(isExpanded ? null : category);
                // scroll to chip after expansion, if needed
                if (!isExpanded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // get the build context of the expanded tile via its key
                    final ctx = tileKey?.currentContext;
                    if (ctx != null) {
                      // wait till next frame so layout is complete
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // get the tiles position on screen
                        final renderBox = ctx.findRenderObject() as RenderBox;
                        final position =
                            renderBox.localToGlobal(Offset.zero).dy;
                        final screenHeight = MediaQuery.of(ctx).size.height;
                        // check if the tile is pushed too far down
                        final isTooLow = position > screenHeight * 0.6;

                        // scroll to make tile visible (middle ish of the screen)
                        Scrollable.ensureVisible(
                          ctx,
                          duration: const Duration(milliseconds: 400),
                          alignment: isTooLow ? 0.05 : 0.1,
                          curve: Curves.easeInOut,
                        );
                      });
                    }
                  });
                }
              },
              // list of entries for that day
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                // show content only if expanded
                child: Container(
                  decoration: BoxDecoration(
                    // base colour for chip
                    color: AppTheme.getCategoryColor(category, isDark),
                    borderRadius: BorderRadius.circular(30),
                    border: isExpanded
                        ? Border.all(
                            // highlight border when expanded, for focused look
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      // header category + count
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: isRefreshing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    // label + entries
                                    '$category: $count',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimaryLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.baseBlack),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  // label + entries
                                  '$category: $count',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimaryLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                      // content section - entries list for the category (if expanded)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Container(
                                decoration: BoxDecoration(
                                  // lighter background for the chip children entry list
                                  color: AppTheme.getLighterCategoryColor(
                                      category, isDark),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                ),
                                child: Column(
                                  // build list of entry tiles
                                  children: entries.map((entry) {
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      title: Text(
                                        entry.text,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimaryLight),
                                      ),
                                      subtitle: Text(
                                        // format timestamp per entry day month, hour:minute
                                        DateFormat('dd MMM, HH:mm')
                                            .format(entry.timestamp),
                                        style: const TextStyle(
                                            color: AppTheme.textSecondaryLight),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(), // hidden when collapsed
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }
}
