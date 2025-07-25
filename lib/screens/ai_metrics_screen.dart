// ai_metrics_screen.dart, optional and uses internet

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trackbackapp/widgets/expandable_chips.dart';
import 'settings_screen.dart';
import '../utils/week_selection_utils.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../services/groq_service.dart';
import '../models/entry.dart';
import '../utils/hive_utils.dart';
import '../utils/constants.dart';
import '../utils/calendar_utils.dart';
import '../utils/month_year_utils.dart';
import '../theme.dart';

enum TimeFilter { all, day, week, month, year }

class AiMetricsScreen extends ConsumerStatefulWidget {
  const AiMetricsScreen({super.key});

  @override
  ConsumerState<AiMetricsScreen> createState() => AiMetricsScreenState();
}

class AiMetricsScreenState extends ConsumerState<AiMetricsScreen> {
  bool isRefreshing = false;
  Map<String, int> labelCounts = {};
  Map<String, List<Entry>> labelToEntries = {};
  DateTime? lastUpdated;
  String? expandedCategory;
  OverlayEntry? filterOverlayEntry;

  final Map<String, GlobalKey> categoryKeys = {
    for (var c in standardCategories) c: GlobalKey()
  };

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  DateTime? focusedWeek;
  DateTime? selectedWeek;
  DateTime rangeStartDay = DateTime.now();
  DateTime rangeEndDay = DateTime.now();

  DateTime focusedMonth = DateTime.now();
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

    focusedDay = now;
    selectedDay = now;

    rangeStartDay = normalizedNow;
    rangeEndDay = normalizedNow.add(const Duration(days: 6));

    selectedWeek = updateWeekRange(normalizedNow);
    focusedWeek = normalizedNow;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadStoredMetrics(); // reload data when navigating back to the page
  }

  Future<void> loadStoredMetrics() async {
    final storedLabels = await getLabelsFromHive();
    final timestamp = await getLastUpdatedFromHive();
    final dateEntriesMap = ref.read(dateEntriesProvider);
    final allEntries = dateEntriesMap.values.expand((list) => list).toList();

    // map to group entries by category
    Map<String, List<Entry>> entriesByCategory = {};

    // populate entriesByCategory map with entries from allEntries
    for (final entry in allEntries) {
      String label = entry.label;

      if (label.isNotEmpty) {
        final category = getBroaderCategory(label);

        // only add entries that have a matching category in storedLabels
        if (storedLabels.containsKey(category)) {
          entriesByCategory.putIfAbsent(category, () => []).add(entry);
        }
      }
    }

    setState(() {
      labelCounts = {...storedLabels}; // copy the stored counts
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
    Map<String, List<Entry>> newLabelToEntries = {};
    Map<String, List<Entry>> updatedEntriesByDate = {};

    for (final entry in allEntries) {
      String label = entry.label;
      if (label.isEmpty) {
        label = await GroqService.classifySingleText(entry.text);
      }

      final validLabel = label.isNotEmpty ? label : 'Uncategorized';
      final category = getBroaderCategory(validLabel);

      final updatedEntry = entry.copyWith(label: validLabel);

      newLabelCounts[category] = (newLabelCounts[category] ?? 0) + 1;
      newLabelToEntries.putIfAbsent(category, () => []).add(updatedEntry);

      final dateKey = DateFormat('yyyy-MM-dd').format(updatedEntry.timestamp);
      updatedEntriesByDate.putIfAbsent(dateKey, () => []).add(updatedEntry);
    }

    await storeLabelsInHive(newLabelCounts);
    final now = DateTime.now();
    await storeLastUpdatedInHive(now);

    // update the provider and persist updated entries with their new labels
    ref.read(dateEntriesProvider.notifier).replaceAll(updatedEntriesByDate);

    setState(() {
      labelCounts = newLabelCounts;
      labelToEntries = newLabelToEntries;
      lastUpdated = now;
      isRefreshing = false;
    });
  }

  String getBroaderCategory(String label) {
    if (standardCategories.contains(label)) {
      label;
    }
    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackBack'),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
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
      body: Padding(
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
                    final isAlreadySelected = selectedFilter == filter;

                    // update selected filter state only if it is a new selection
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
                    final entries = labelToEntries[filter.name] ?? [];
                    showFilterOverlay(offset, size, filter, isLastChip,
                        entries: entries);
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

  List<DateTime> getAvailableDates(List<Entry> entries) {
    return entries
        .map((entry) => DateTime(
            entry.timestamp.year, entry.timestamp.month, entry.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  List<int> getAvailableMonths(List<Entry> entries) {
    return entries.map((entry) => entry.timestamp.month).toSet().toList();
  }

  List<int> getAvailableYears(List<Entry> entries) {
    return entries.map((entry) => entry.timestamp.year).toSet().toList();
  }

  List<String> getAvailableWeeks(List<Entry> entries) {
    return entries
        .map((entry) {
          final startOfWeek = entry.timestamp
              .subtract(Duration(days: entry.timestamp.weekday - 1));
          return "${startOfWeek.year}-${startOfWeek.month}-${startOfWeek.day}";
        })
        .toSet()
        .toList();
  }

  // show an overlay positioned below the selected chip, aligned based on chips screen position
  void showFilterOverlay(
      Offset offset, Size chipSize, TimeFilter filter, bool alignRight,
      {List<Entry> entries = const []}) {
    removeFilterOverlay(); // remove previous overlay if any

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    const double overlayWidth = 250;
    // const double overlayHeight = 300;
    double leftPosition;

    bool hasInitializedWeek = false;

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
                            updateWeekRange(focusedDay);
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
                                    focusedDay: focusedDay,
                                    selectedDay: selectedDay,
                                    onDaySelected: (selected, focused) {
                                      setState(() {
                                        selectedDay = selected;
                                        focusedDay = focused;
                                      });
                                      setStateOverlay(() {});
                                    },
                                    isDark: isDark,
                                    currentVisibleMonth: currentVisibleMonth,
                                    onVisibleMonthChanged: (newMonth) {
                                      setState(() {
                                        currentVisibleMonth = newMonth;
                                      });
                                    },
                                    setState: (fn) => setState(fn),
                                  ),

                                if (filter == TimeFilter.week)
                                  buildWeekCalendar(
                                    currentVisibleMonth: currentVisibleMonth,
                                    onVisibleMonthChanged: (newMonth) {
                                      setState(() {
                                        currentVisibleMonth = newMonth;
                                      });
                                    },
                                    focusedWeek: focusedWeek ?? DateTime.now(),
                                    selectedWeek: selectedWeek,
                                    onWeekSelected: (selected, focused) {
                                      setState(() {
                                        selectedWeek = selected;
                                        focusedWeek = focused;
                                      });
                                      setStateOverlay(() {});
                                    },
                                    isDark: isDark,
                                    calendarStyle: calendarStyle,
                                    setStateOverlay: () =>
                                        setStateOverlay(() {}),
                                    setState: (fn) => setState(fn),
                                  ),

                                if (filter == TimeFilter.month)
                                  buildMonthView(
                                    filter: filter,
                                    focusedMonth: focusedMonth,
                                    selectedMonth: selectedMonth,
                                    onSelectedMonth: (selected, focused) {
                                      setState(() {
                                        selectedMonth = selected;
                                        focusedMonth = focused;
                                      });

                                      setStateOverlay(
                                          () {}); // rebuild the overlay
                                    },
                                    // filtering logic

                                    isDark: isDark,
                                    availableData: availableMonthData,
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
                                    // filtering logic

                                    isDark: isDark,
                                    availableData: availableYearData,
                                  ),

                                const SizedBox(height: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    // accept and close the overlay, filtering the data below based on the selection
                                    removeFilterOverlay();
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
}
