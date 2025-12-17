// ai_metrics_screen.dart, optional screen that uses ai and internet to show productivity metrics based on entries

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/date_entries_provider.dart';
import '../services/groq_service.dart';
import '../models/entry.dart';
import '../utils/week_selection_utils.dart';
import '../utils/hive_utils.dart';
import '../utils/constants.dart';
import '../utils/date_week_utils.dart';
import '../utils/aimetrics_category_utils.dart';
import '../utils/aimetrics_filter_utils.dart';
import '../utils/month_year_utils.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_fab.dart';
import '../widgets/expandable_chips.dart';
import '../widgets/responsive_screen.dart';
import '../theme.dart';

enum TimeFilter { all, day, week, month, year }

class AiMetricsScreen extends ConsumerStatefulWidget {
  const AiMetricsScreen({super.key});

  @override
  ConsumerState<AiMetricsScreen> createState() => AiMetricsScreenState();
}

class AiMetricsScreenState extends ConsumerState<AiMetricsScreen> {
  EntryRangeInfo entryRange = EntryRangeInfo(
    firstDate: DateTime.now(),
    lastDate: DateTime.now(),
    availableDays: {},
    availableWeeks: {},
    availableMonths: {},
    availableYears: {},
  );
  bool isRefreshing = false;
  Map<String, int> labelCounts = {};
  Map<String, List<Entry>> labelToEntries = {};
  DateTime? lastUpdated;
  String? expandedCategory;
  OverlayEntry? filterOverlayEntry;

  List<Entry> allEntries = [];

  // to handle disabled to select date/ week/ month/ year with a dynamic hint message
  DateTime? tappedDisabledEntry;
  Offset? tappedOffset;

  final Map<String, GlobalKey> categoryKeys = {
    for (var c in standardCategories) c: GlobalKey()
  };

  DateTime selectedDay = DateTime.now();

  DateTime clampFocusedDay(DateTime focus, DateTime first, DateTime last) {
    if (focus.isBefore(first)) return first;
    if (focus.isAfter(last)) return last;
    return focus;
  }

  DateTime clampFocusedWeek(DateTime? focus, DateTime first, DateTime last) {
    if (focus == null) return DateTime.now();

    if (focus.isBefore(first)) return first;
    if (focus.isAfter(last)) return last;

    return focus;
  }

  DateTime? focusedDay;
  DateTime? focusedWeek;
  DateTime? selectedWeek;
  DateTime rangeStartDay = DateTime.now();
  DateTime rangeEndDay = DateTime.now();

  DateTime? focusedMonth;
  DateTime selectedMonth = DateTime.now();
  Set<DateTime> availableMonthData = {};

  DateTime focusedYear = DateTime.now();
  DateTime selectedYear = DateTime.now();

  DateTime currentVisibleMonth = DateTime.now();

  Set<DateTime> availableYearData = {};

  TimeFilter selectedFilter = TimeFilter.all;
  final ScrollController chipScrollController = ScrollController();
  final List<GlobalKey> chipKeys =
      List.generate(TimeFilter.values.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    loadStoredMetrics(); // load the metrics immediately on page load
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);

    // wait until entryRange is set before clamping
    if (entryRange.firstDate.isBefore(entryRange.lastDate)) {
      focusedDay = clampFocusedDay(
          normalizedNow, entryRange.firstDate, entryRange.lastDate);
      selectedDay = focusedDay!;
    } else {
      // fallback for first run before data load
      focusedDay = normalizedNow;
      selectedDay = normalizedNow;
    }
    debugPrint("before rangeStartDay: $rangeStartDay");
    debugPrint("before rangeEndDay: $rangeEndDay");

    rangeStartDay = normalizedNow;
    rangeEndDay = normalizedNow.add(const Duration(days: 6));

    debugPrint("after rangeStartDay: $rangeStartDay");
    debugPrint("after rangeEndDay: $rangeEndDay");

    selectedWeek = updateWeekRange(normalizedNow);
    focusedWeek = normalizedNow;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = ref.read(hiveBoxProvider);
      final stored = box.get('entries');

      final List<Entry> all = stored != null && stored is Map
          ? stored.values.expand((rawList) {
              if (rawList is! List) return <Entry>[];
              return rawList.map<Entry?>((item) {
                try {
                  final json = jsonDecode(item);
                  return Entry.fromJson(json);
                } catch (_) {
                  return null;
                }
              }).whereType<Entry>();
            }).toList()
          : [];

      final newRange = calculateEntryRangeInfo(all);

      if (mounted) {
        setState(() {
          allEntries = all;
          labelToEntries = groupEntriesByLabel(all);
          entryRange = newRange;

          // week
          focusedWeek = clampFocusedWeek(
              focusedWeek, newRange.firstDate, newRange.lastDate);

          // update week range using new entry data
          rangeStartDay = getStartOfWeek(focusedWeek!);
          rangeEndDay = getEndOfWeek(focusedWeek!);

          // month
          focusedMonth = newRange.lastDate;
          selectedMonth = newRange.lastDate;
          availableMonthData = newRange.availableMonths;

          // year
          final lastYear = newRange.lastDate.year;
          focusedYear = DateTime(lastYear);
          selectedYear = DateTime(lastYear);
          availableYearData = newRange.availableMonths;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isRefreshing) {
      loadStoredMetrics();
    }
    // loadStoredMetrics(); // reload data when navigating back to the page
  }

  Future<void> loadStoredMetrics() async {
    // final storedLabels = await getLabelsFromHive();
    final timestamp = await getLastUpdatedFromHive();
    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    // map to group entries by category
    // Map<String, List<Entry>> entriesByCategory = {};
    final Map<String, List<Entry>> entriesByCategory = {
      for (final c in standardCategories) c: [],
    };

    // populate entriesByCategory map with entries from allEntries
    for (final entry in allEntries) {
      // String label = entry.label;
      if (entry.label.isEmpty) continue;

      final category = getBroaderCategory(entry.label);
      if (entriesByCategory.containsKey(category)) {
        entriesByCategory[category]!.add(entry);
      }

      // if (label.isNotEmpty) {
      //   final category = getBroaderCategory(label);

      //   // only add entries that have a matching category in storedLabels
      //   if (storedLabels.containsKey(category)) {
      //     entriesByCategory.putIfAbsent(category, () => []).add(entry);
      //   }
      // }
    }

    setState(() {
      // labelCounts = {...storedLabels}; // copy the stored counts
      labelToEntries = entriesByCategory; // set the entries map
      lastUpdated = timestamp; // set the last updated timestamp
    });
  }

  Future<void> refreshMetrics() async {
    setState(() {
      isRefreshing = true;
    });

    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    Map<String, int> newLabelCounts = {};

    // Map<String, List<Entry>> newLabelToEntries = {};
    final Map<String, List<Entry>> newLabelToEntries = {
      for (final category in standardCategories) category: [],
    };

    Map<String, List<Entry>> updatedEntriesByDate = {};

    for (final entry in allEntries) {
      String label = entry.label;
      if (label.isEmpty) {
        label = await GroqService.classifySingleText(entry.text);
      }

      // final validLabel = label.isNotEmpty ? label : 'Uncategorized';
      // final category = getBroaderCategory(validLabel);

      final validLabel = label.isNotEmpty ? label : 'Idle';

      String category = getBroaderCategory(validLabel);

      // safety net — force into known buckets
      if (!standardCategories.contains(category)) {
        category = 'Idle';
      }

      final updatedEntry = Entry(
        text: entry.text,
        label: validLabel,
        timestamp: entry.timestamp,
      );

      // final updatedEntry = entry.copyWith(label: validLabel);

      newLabelCounts[category] = (newLabelCounts[category] ?? 0) + 1;
      newLabelToEntries.putIfAbsent(category, () => []).add(updatedEntry);

      // final dateKey = DateFormat('yyyy-MM-dd').format(updatedEntry.timestamp);
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);

      updatedEntriesByDate.putIfAbsent(dateKey, () => []).add(updatedEntry);
    }

    debugPrint(
        'LABEL DUMP → ${updatedEntriesByDate.values.expand((e) => e).map((e) => e.label).toSet()}');

    await storeLabelsInHive(newLabelCounts);
    final now = DateTime.now();
    await storeLastUpdatedInHive(now);

    // update the provider and persist updated entries with their new labels
    ref.read(dateEntriesProvider.notifier).replaceAll(updatedEntriesByDate);

    final verify = ref.read(dateEntriesProvider);
    debugPrint('AFTER REPLACE → total entries: '
        '${verify.values.expand((e) => e).length}');

    setState(() {
      labelCounts = newLabelCounts;
      labelToEntries = newLabelToEntries;
      lastUpdated = now;
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(),
      floatingActionButton: CustomFAB(
        child: isRefreshing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppTheme.baseBlack : AppTheme.baseWhite,
                  ),
                ),
              )
            : const Icon(Icons.refresh),
        onPressed: () async {
          if (!isRefreshing) {
            setState(() {
              isRefreshing = true;
            });
            await clearStoredLabels();
            await refreshMetrics();
          }
        },
      ),
      body: ResponsiveScreen(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'AI Categorised Labels:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                buildFilterChips(theme, isDark),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    lastUpdated != null
                        ? 'Last updated: ${DateFormat('dd-MMM-yy, HH:mm').format(lastUpdated!)} hrs'
                        : 'Last updated: Never. Add entries in Home and press Refresh button here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                AiMetricsExpansionTiles(
                  labelToEntries: labelToEntries,
                  expandedCategory: expandedCategory,
                  isRefreshing: isRefreshing,
                  onTap: (category) {
                    setState(() {
                      expandedCategory = category;
                    });
                  },
                  isDark: isDark,
                  categoryKeys: categoryKeys,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFilterChips(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          controller: chipScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TimeFilter.values.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: RawChip(
                  key: chipKeys[index],
                  label: Text(
                    filter.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? AppTheme.baseWhite : AppTheme.baseBlack)
                          : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  // made async to ensure chip scrolls into view before calculating its position for overlay alignment
                  onSelected: (selected) async {
                    // if the same chip is tapped on again, reopen the overlay manually
                    // commented for now to move the actual selection logic inside the ok button
                    final isAlreadySelected = selectedFilter == filter;

                    if (filter == TimeFilter.all) {
                      final updatedLabelToEntries = getFilteredLabelEntries(
                        entries: allEntries,
                        filter: filter,
                        selectedDay: selectedDay,
                        selectedWeek: selectedWeek,
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                      );
                      setState(() {
                        selectedFilter = filter;
                        labelToEntries = updatedLabelToEntries;
                      });
                      removeFilterOverlay();
                      return;
                    }

                    // update selected filter state only if it is a new selection
                    // this is required to 'select' the new chip while awaiting the actual overlay selection + ok for dynamic data display
                    if (!isAlreadySelected) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    }

                    // get the context for this chip from its globalkey
                    final chipContext = chipKeys[index].currentContext;
                    if (chipContext == null) return;

                    // scroll the selected chip into view in case it is offscreen
                    // current position for this piece of code, since All gives issues otherwise
                    await Scrollable.ensureVisible(
                      chipContext,
                      duration: const Duration(milliseconds: 300),
                      alignment: 0.5, // center the chip in view
                      curve: Curves.easeInOut,
                    );

                    // small delay to ensure layout has fully updated after scroll
                    await Future.delayed(const Duration(milliseconds: 10));

                    // prevent context access if widget was disposed during await gap
                    if (!chipContext.mounted) return;

                    // if All filter is selected, no overlay required - exit from here
                    // current position for this piece of code, since All gives issues otherwise
                    // scroll must already happen before this check, else All does not move back into position
                    if (filter == TimeFilter.all) {
                      final updatedLabelToEntries = getFilteredLabelEntries(
                        entries: allEntries,
                        filter: filter,
                        selectedDay: selectedDay,
                        selectedWeek: selectedWeek,
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                      );
                      setState(() {
                        selectedFilter = filter;
                        labelToEntries = updatedLabelToEntries;
                      });
                      removeFilterOverlay();
                      return; // skip overlay only for the 'all' pill filter
                    }

                    // for all other filters, calculate the chips screen position
                    final renderBox =
                        chipContext.findRenderObject() as RenderBox;
                    final offset = renderBox.localToGlobal(Offset.zero);
                    final size = renderBox.size;

                    // track if this is the last chip
                    // required for the position overlay
                    // which, for the last chip, is aligned right unlike the center alignment for the rest
                    final isLastChip = index == TimeFilter.values.length - 1;

                    final entries =
                        labelToEntries.values.expand((list) => list).toList();

                    showFilterOverlay(
                      offset,
                      size,
                      filter,
                      isLastChip,
                      entries: entries,
                      entryRange: entryRange,
                    );
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: AppTheme.weekHighlightDark,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.weekHighlightDark,
                      // : AppTheme.textHintDark,
                      width: 1.2,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void scrollToSelectedChip(int index) {
    final keyContext = chipKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    }
  }

  // show an overlay positioned below the selected chip, aligned based on chips screen position
  void showFilterOverlay(
      Offset offset, Size chipSize, TimeFilter filter, bool alignRight,
      {required EntryRangeInfo entryRange, List<Entry> entries = const []}) {
    debugPrint(' showFilterOverlay called with:');
    debugPrint('Filter: ${filter.name}');
    debugPrint('entryRange.availableMonths: ${entryRange.availableMonths}');
    debugPrint('entryRange.availableYears: ${entryRange.availableYears}');

    removeFilterOverlay(); // remove previous overlay if any

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    const double overlayWidth = 250;
    // const double overlayHeight = 300;
    double leftPosition;

    // final entryInfo = calculateEntryRangeInfo(allEntries);
    final entryInfo = entryRange;

    bool hasInitializedWeek = false;

    final firstDate = allEntries.isNotEmpty
        ? allEntries
            .map((e) => e.timestamp)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : DateTime.now().subtract(const Duration(days: 365));

    final lastDate = allEntries.isNotEmpty
        ? allEntries
            .map((e) => e.timestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();

    // if the chip is the last one (far right), align overlay to its right edge
    // otherwise center overlay under the respective chip
    if (alignRight) {
      leftPosition = offset.dx + chipSize.width - overlayWidth;
    } else {
      leftPosition = offset.dx + (chipSize.width / 2) - (overlayWidth / 2);
    }

    // prevent the overlay from overflowing the screen
    leftPosition =
        leftPosition.clamp(8.0, screenSize.width - overlayWidth - 8.0);

    late OverlayEntry tempOverlay;

    tempOverlay = OverlayEntry(
        builder: (context) => Stack(children: [
              // dismiss background taps - do not close the overlay if anywhere on the overlay is tapped
              ModalBarrier(
                dismissible: true,
                color: Colors.transparent,
                onDismiss: () {
                  removeFilterOverlay();
                },
              ),
              Stack(children: [
                Positioned(
                  left: leftPosition,
                  top: offset.dy + chipSize.height + 6, // just below the chip
                  width: overlayWidth,
                  child: Material(
                    elevation: 6,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                        maxWidth: 260,
                      ),
                      child:
                          StatefulBuilder(builder: (context, setStateOverlay) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final calendarStyle = CalendarStyle(
                          todayDecoration: isDark
                              ? AppTheme.calendarTodayDecorationDark
                              : AppTheme.calendarTodayDecorationLight,
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: isDark
                              ? AppTheme.calendarDayTextDark
                              : AppTheme.calendarDayTextLight,
                          weekendTextStyle: isDark
                              ? AppTheme.calendarWeekendTextDark
                              : AppTheme.calendarWeekendTextLight,
                          outsideTextStyle: isDark
                              ? AppTheme.calendarOutsideTextDark
                              : AppTheme.calendarOutsideTextLight,
                          selectedTextStyle:
                              const TextStyle(color: AppTheme.baseWhite),
                          cellMargin: const EdgeInsets.all(2),
                        );

                        if (filter == TimeFilter.week && !hasInitializedWeek) {
                          hasInitializedWeek = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            updateWeekRange(focusedDay ?? DateTime.now());
                            setState(() {});
                            setStateOverlay(() {});
                          });
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // close button aligned top right
                                SizedBox(
                                  height: 15,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => removeFilterOverlay(),
                                          child:
                                              const Icon(Icons.close, size: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // pill select content
                                if (filter == TimeFilter.day)
                                  buildDayCalendar(
                                    filter: filter,
                                    focusedDay: focusedDay ?? DateTime.now(),
                                    selectedDay: selectedDay,
                                    onDaySelected: (selected, focused) {
                                      setState(() {
                                        selectedDay = selected;
                                        focusedDay = focused;
                                      });
                                      setStateOverlay(
                                          () {}); // rebuild the overlay
                                    },
                                    isDark: isDark,
                                    currentVisibleMonth: currentVisibleMonth,
                                    onVisibleMonthChanged: (newMonth) {
                                      setState(() {
                                        currentVisibleMonth = newMonth;
                                      });
                                    },
                                    setState: (fn) => setState(fn),
                                    firstMonth: DateTime(
                                        firstDate.year, firstDate.month),
                                    lastMonth:
                                        DateTime(lastDate.year, lastDate.month),
                                    entryInfo: entryInfo,
                                    onDisabledDayTap: onDisabledTap,
                                  ),

                                if (filter == TimeFilter.week)
                                  buildWeekCalendar(
                                    allEntries: allEntries,
                                    currentVisibleMonth: currentVisibleMonth,
                                    onVisibleMonthChanged: (newMonth) {
                                      setState(() {
                                        currentVisibleMonth = newMonth;
                                      });
                                    },
                                    focusedWeek: clampFocusedWeek(
                                      focusedWeek ?? DateTime.now(),
                                      entryRange.firstDate,
                                      entryRange.lastDate,
                                    ),

                                    selectedWeek: selectedWeek,
                                    onWeekSelected: (selected, focused) {
                                      setState(() {
                                        final normalized = DateTime(
                                            selected.year,
                                            selected.month,
                                            selected.day);
                                        selectedWeek = normalized;
                                        focusedWeek = normalized;
                                        updateWeekRange(normalized);
                                      });
                                      setStateOverlay(
                                          () {}); // rebuild the overlay
                                    },
                                    isDark: isDark,
                                    calendarStyle: calendarStyle,
                                    setStateOverlay: () => setStateOverlay(
                                        () {}), // rebuild the overlay
                                    setState: (fn) => setState(fn),
                                    firstMonth: DateTime(
                                        firstDate.year, firstDate.month),
                                    lastMonth:
                                        DateTime(lastDate.year, lastDate.month),
                                    entryInfo: entryInfo,
                                    onDisabledWeekTap: onDisabledTap,
                                  ),

                                if (filter == TimeFilter.month)
                                  buildMonthView(
                                    filter: filter,
                                    focusedMonth:
                                        focusedMonth ?? DateTime.now(),
                                    selectedMonth: selectedMonth,
                                    onSelectedMonth: (selected, focused) {
                                      setState(() {
                                        selectedMonth = selected;
                                        focusedMonth = focused;
                                      });

                                      setStateOverlay(
                                          () {}); // rebuild the overlay
                                    },
                                    isDark: isDark,
                                    entryRange: entryRange,
                                  ),

                                if (filter == TimeFilter.year)
                                  buildYearView(
                                    filter: filter,
                                    focusedYear: focusedYear,
                                    selectedYear: selectedYear,
                                    onSelectedYear: (selected, focused) {
                                      setState(() {
                                        selectedYear = selected;
                                        focusedYear = focused;
                                      });

                                      setStateOverlay(
                                          () {}); // rebuild the overlay
                                    },
                                    onFocusedYearChanged: (newFocused) {
                                      setState(() {
                                        focusedYear = newFocused;
                                      });
                                      setStateOverlay(
                                          () {}); // rebuild the overlay
                                    },
                                    isDark: isDark,
                                    availableData: availableYearData,
                                    entryRange: entryRange,
                                  ),

                                const SizedBox(height: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    removeFilterOverlay();
                                    // accept and close the overlay, filtering the data below based on the selection
                                    debugPrint("selectedMonth: $selectedMonth");
                                    debugPrint("selectedYear: $selectedYear");

                                    final referenceDate =
                                        getReferenceDateForFilter(
                                      filter: filter,
                                      selectedDay: selectedDay,
                                      selectedWeek: selectedWeek,
                                      selectedMonth: selectedMonth,
                                      selectedYear: selectedYear,
                                    );

                                    debugPrint("=== Before Filtering ===");
                                    debugPrint("Filter: $filter");
                                    debugPrint(
                                        "Reference Date: $referenceDate");

                                    final updatedLabelToEntries =
                                        getFilteredLabelEntries(
                                      entries: allEntries,
                                      filter: filter,
                                      selectedDay: selectedDay,
                                      selectedWeek: selectedWeek,
                                      selectedMonth: selectedMonth,
                                      selectedYear: selectedYear,
                                    );
                                    debugPrint("FILTER: $filter");
                                    debugPrint("SELECTED DAY: $selectedDay");
                                    debugPrint("SELECTED WEEK: $selectedWeek");
                                    debugPrint(
                                        "SELECTED MONTH: $selectedMonth");
                                    debugPrint("SELECTED YEAR: $selectedYear");

                                    debugPrint("Grouped Entries:");
                                    updatedLabelToEntries
                                        .forEach((label, list) {
                                      debugPrint("$label → ${list.length}");
                                    });

                                    setState(() {
                                      selectedFilter = filter;
                                      labelToEntries = updatedLabelToEntries;
                                    });
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ]),
            ]));

    // insert overlay into the ui
    overlay.insert(tempOverlay);
    filterOverlayEntry = tempOverlay; // save reference to remove later
  }

  // remove curerntly active filter overlay from the ui, if any
  void removeFilterOverlay() {
    filterOverlayEntry?.remove();
    filterOverlayEntry = null;
  }

  void onDisabledTap(DateTime disabledEntry, Offset offset) {
    setState(() {
      tappedDisabledEntry = disabledEntry;
      tappedOffset = offset;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          tappedDisabledEntry = null;
        });
      }
    });
  }

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime getEndOfWeek(DateTime date) {
    return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }
}
