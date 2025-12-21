// trends_screen.dart, display bar charts for total entries and pie charts for badges earned

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/hive_utils.dart';
import '../utils/time_utils.dart';
import '../providers/date_entries_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_fab.dart';
import '../widgets/responsive_screen.dart';
import '../metrics/trends_metrics_utils.dart';
import '../metrics/trends_charts.dart';
import '../models/entry.dart';
import '../theme.dart';

// ConsumerStatefulWidget for reactive access to dateEntriesProvider
class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => TrendsScreenState();
}

// TabController requires a vsync source
// TickerProviderStateMixin prevents offscreen animation ticks and memory leaks
// and allows smooth lifecycle aware tab transitions
class TrendsScreenState extends ConsumerState<TrendsScreen>
    with TickerProviderStateMixin {
  // active aggregation mode for metrics, drives filtering, labels and navigation logic
  String viewType = 'Day';

  // anchor date for the current view, meaning changes by viewtype - day/week/momth/year start
  DateTime referenceDate = DateTime.now();

  bool isBarChart = true;
  late TabController tabController;

  // local selection used for filtering
  late DateTime selectedDate;

  // shortcut to avoid repeated provider reads
  Map<String, List<Entry>> get dateEntries => ref.read(dateEntriesProvider);
  // cache computed metrics to avoid recomputing heavy aggregates on every rebuild
  final Map<String, Map<String, dynamic>> metricsCache =
      {}; // keyed as "$viewType|$refDateIso"

  // lazy background metrics cache
  bool isBackgroundLoading = false;

  // lazily populate cache for all views
  Map<String, dynamic>?
      metricsCacheByView; // keyed by viewType, each value has 'entries' (iso), 'times', 'badgeCountMap'

  // lazy gather timestamp and precompute metrics for other views in background isolate
  // day view renders immediately, others hydrate lazily
  Future<void> startBackgroundLoad() async {
    final dateEntriesMap = ref.read(dateEntriesProvider);
    if (dateEntriesMap.isEmpty) return;

    // serialise timstamps only (lighter payload for isolates)
    final timestamps = dateEntriesMap.values
        .expand((list) => list)
        .map((e) => e.timestamp.toIso8601String())
        .toList();

    if (timestamps.isEmpty) return;

    setState(() {
      isBackgroundLoading = true;
    });

    // compute() can fail silently or throw to avoid ui crash or stuck loading
    try {
      // compute metrics for day/ week/ month/ year (day will be returned but day is also instantly rendered)
      final result = await compute(
        computeMetricsForAllViews,
        {
          'timestamps': timestamps,
          'viewTypes': ['Day', 'Week', 'Month', 'Year'],
          'selectedDate': referenceDate.toIso8601String(),
        },
      );

      if (!mounted) return;

      setState(() {
        metricsCacheByView = Map<String, dynamic>.from(result);
        isBackgroundLoading = false;
      });
    } catch (e) {
      // if compute fails stop loading and keep ui responsive
      if (!mounted) return;
      setState(() {
        isBackgroundLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();

    // fixed 4 views
    tabController = TabController(length: 4, vsync: this);
    // sync viewtype when user taps a tab
    tabController.addListener(() {
      setState(() {
        switch (tabController.index) {
          case 0:
            viewType = 'Day';
            break;
          case 1:
            viewType = 'Week';
            break;
          case 2:
            viewType = 'Month';
            break;
          case 3:
            viewType = 'Year';
            break;
        }
        updateReferenceDate();
      });
    });
    updateReferenceDate();
  }

  // normalise referencedate based on viewtype
  // to ensure navigation always moves in full logical units
  void updateReferenceDate() {
    final now = DateTime.now();
    switch (viewType) {
      case 'Day':
        referenceDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        referenceDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Month':
        referenceDate = DateTime(now.year, now.month);
        break;
      case 'Year':
        referenceDate = DateTime(now.year);
        break;
    }
  }

  // move referencedate backward or forward by one logical unit, -1 back, +1 forward
  void moveReferenceDate(int direction) {
    setState(() {
      if (viewType == 'Day') {
        referenceDate = referenceDate.add(Duration(days: direction));
      } else if (viewType == 'Week') {
        referenceDate = referenceDate.add(Duration(days: 7 * direction));
      } else if (viewType == 'Month') {
        referenceDate =
            DateTime(referenceDate.year, referenceDate.month + direction);
      } else if (viewType == 'Year') {
        referenceDate = DateTime(referenceDate.year + direction);
      }
    });
  }

  // user facing label for the current reference window
  // intuitive today/ yesterday/ this week/ this month/ this year etc wherever applicable
  String getDisplayText() {
    final now = DateTime.now();

    if (viewType == 'Day') {
      if (referenceDate.year == now.year &&
          referenceDate.month == now.month &&
          referenceDate.day == now.day) {
        return 'Today';
      } else if (referenceDate.year == now.year &&
          referenceDate.month == now.month &&
          referenceDate.day == now.day - 1) {
        return 'Yesterday';
      } else {
        return DateFormat('dd MMM').format(referenceDate);
      }
    } else if (viewType == 'Week') {
      final startOfWeek =
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (startOfWeek.isBefore(now) && now.isBefore(endOfWeek)) {
        return 'This Week';
      } else {
        return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';
      }
    } else if (viewType == 'Month') {
      if (referenceDate.year == now.year && referenceDate.month == now.month) {
        return 'This Month';
      } else {
        return DateFormat('MMMM').format(referenceDate);
      }
    } else if (viewType == 'Year') {
      if (referenceDate.year == now.year) {
        return 'This Year';
      } else {
        return referenceDate.year.toString();
      }
    }
    return '';
  }

  // prevent navigating before first recorded entry to avoid showing empty charts and hardcoding the oldest view
  bool canMoveBack() {
    // final now = DateTime.now();
    final allEntries = dateEntries.values.expand((list) => list).toList();
    final firstEntryDate = getFirstEntryDate(allEntries);

    if (viewType == 'Day') {
      return referenceDate.isAfter(firstEntryDate);
    }

    if (viewType == 'Week') {
      final startOfWeek =
          referenceDate.subtract(Duration(days: referenceDate.weekday - 1));

      return startOfWeek.isAfter(firstEntryDate);
    }

    if (viewType == 'Month') {
      final startOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);

      return startOfMonth.isAfter(firstEntryDate);
    }

    if (viewType == 'Year') {
      final startOfYear = DateTime(referenceDate.year, 1, 1);

      return startOfYear.isAfter(firstEntryDate);
    }

    return false;
  }

  // prevent navigating into the future
  bool canMoveForward() {
    final now = DateTime.now();

    if (viewType == 'Day') {
      final today = DateTime(now.year, now.month, now.day);

      return referenceDate.isBefore(today);
    }

    if (viewType == 'Week') {
      final startOfWeek = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1)); // start week mon

      final endOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + 6, // sunday of the current week
        23, 59, 59, 999, // last moment of sunday
      ); // end week sun

      final canMove = endOfWeek.isBefore(now);

      return canMove;
    }

    if (viewType == 'Month') {
      final canMove = referenceDate.year < now.year ||
          (referenceDate.year == now.year && referenceDate.month < now.month);

      return canMove;
    }

    if (viewType == 'Year') {
      final canMove = referenceDate.year < now.year;

      return canMove;
    }

    return false;
  }

  // load metrics lazily for a specific view/date pair
  // heavy computation si offloaded to an isolate
  Future<void> loadMetrics(String viewType, DateTime date) async {
    final key = "$viewType|${date.toIso8601String()}";
    if (metricsCache.containsKey(key)) return; // already cached

    final timestamps = flattenEntries(ref.read(dateEntriesProvider))
        .map((e) => e.timestamp.toIso8601String())
        .toList();

    if (timestamps.isEmpty) return;

    final result = await compute(
      computeMetricsForSingleView,
      {
        'timestamps': timestamps,
        'viewType': viewType,
        'selectedDate': date.toIso8601String(),
      },
    );

    if (!mounted) return;
    setState(() {
      metricsCache[key] = Map<String, dynamic>.from(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateEntries = ref.watch(dateEntriesProvider);
    final isDark = theme.brightness == Brightness.dark;

    final selectedColor = theme.appBarTheme.iconTheme?.color ??
        (isDark ? AppTheme.baseWhite : AppTheme.baseBlack);
    final unselectedColor =
        isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight;

    final dataMap = <String, int>{};
    for (var entry in dateEntries.entries) {
      dataMap[entry.key] = entry.value.length;
    }

    final hasData = dataMap.isNotEmpty;

    return Scaffold(
      appBar: const CustomAppBar(),
      floatingActionButton: hasData
          ? CustomFAB(
              child: Icon(isBarChart ? Icons.pie_chart : Icons.bar_chart),
              onPressed: () {
                setState(() {
                  isBarChart = !isBarChart;
                });
              },
            )
          : null,
      body: hasData
          ? Builder(builder: (context) {
              // day sync entries
              final todayKey = DateFormat('yyyy-MM-dd').format(referenceDate);
              final List<Entry> todayEntries = dateEntries[todayKey] ?? [];

              // day timestamps for chart
              final List<DateTime> todayTimestamps =
                  todayEntries.map((e) => e.timestamp).toList();

              // counts for time-of-day distribution
              final metricsTimes = {
                'Morning': 0,
                'Afternoon': 0,
                'Evening': 0,
                'Night': 0
              };
              for (final ts in todayTimestamps) {
                final block = getTimeOfDayBlock(ts);
                metricsTimes[block] = (metricsTimes[block] ?? 0) + 1;
              }

              // // calculate badge distribution
              // final badgeCountMap = calculateBadgeCount(
              //   todayEntries,
              //   viewType,
              //   selectedDate: referenceDate,
              // );

              return ResponsiveScreen(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + info button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBarChart
                                ? 'Entries Trend:'
                                : 'Badge Distribution:',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => showBadgeLegend(context),
                            icon: const Icon(Icons.info_outline),
                            tooltip: 'View Badge Details',
                            color: AppTheme.iconDefaultLight,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // container holding the tab section and its content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(children: [
                            // tabbar for day/week/month/year
                            TabBar(
                              controller: tabController,
                              onTap: (index) {
                                final now = DateTime.now();
                                setState(() {
                                  if (index == 0) {
                                    viewType = 'Day';
                                    referenceDate =
                                        DateTime(now.year, now.month, now.day);
                                  } else if (index == 1) {
                                    viewType = 'Week';
                                    referenceDate = now.subtract(
                                        Duration(days: now.weekday - 1));
                                  } else if (index == 2) {
                                    viewType = 'Month';
                                    referenceDate =
                                        DateTime(now.year, now.month);
                                  } else if (index == 3) {
                                    viewType = 'Year';
                                    referenceDate = DateTime(now.year);
                                  }
                                });
                              },
                              dividerColor: Colors.transparent,
                              indicatorColor: Colors.transparent,
                              indicator: UnderlineTabIndicator(
                                borderSide:
                                    BorderSide(color: selectedColor, width: 3),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: selectedColor,
                              unselectedLabelColor: unselectedColor,
                              labelStyle: const TextStyle(
                                fontFamily: 'SF Pro',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.42,
                                letterSpacing: 0.1,
                              ),
                              labelPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              tabs: const [
                                Tab(text: 'Day'),
                                Tab(text: 'Week'),
                                Tab(text: 'Month'),
                                Tab(text: 'Year'),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => showBadgeLegend(context),
                            icon: const Icon(Icons.info_outline),
                            tooltip: 'View Badge Details',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // container holding the tab section and its content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              // tabbar for day/week/month/year
                              TabBar(
                                controller: tabController,
                                onTap: (index) {
                                  final now = DateTime.now();
                                  setState(() {
                                    if (index == 0) {
                                      viewType = 'Day';
                                      referenceDate = DateTime(
                                          now.year, now.month, now.day);
                                    } else if (index == 1) {
                                      viewType = 'Week';
                                      referenceDate = now.subtract(
                                          Duration(days: now.weekday - 1));
                                    } else if (index == 2) {
                                      viewType = 'Month';
                                      referenceDate =
                                          DateTime(now.year, now.month);
                                    } else if (index == 3) {
                                      viewType = 'Year';
                                      referenceDate = DateTime(now.year);
                                    }
                                  });
                                },
                                dividerColor: Colors.transparent,
                                indicatorColor: Colors.transparent,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                      color: selectedColor, width: 3),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      getDisplayText(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: selectedColor,
                                      ),
                                    ),
                                    if (!isOnTodayAnchor()) ...[
                                      const SizedBox(width: 6),
                                      IconButton(
                                        onPressed: () =>
                                            jumpToToday(DateTime.now()),
                                        icon: Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: selectedColor,
                                        ),
                                        tooltip: 'Jump to today',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ],
                                ),
                                IconButton(
                                  onPressed: canMoveForward()
                                      ? () => moveReferenceDate(1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // bar graph or pie chart inside TabBarView
                            Expanded(
                              child: TabBarView(
                                controller: tabController,
                                physics: const NeverScrollableScrollPhysics(),
                                children: ['Day', 'Week', 'Month', 'Year']
                                    .map((tabType) {
                                  // filter entries for this tab
                                  final allEntries = dateEntries.values
                                      .expand((list) => list)
                                      .toList();
                                  final filteredEntries =
                                      filterEntriesByViewType(
                                    allEntries,
                                    tabType,
                                    selectedDate: referenceDate,
                                  );

                                  // badge counts for this tab
                                  final badgeCountMap = calculateBadgeCount(
                                    filteredEntries,
                                    tabType,
                                    selectedDate: referenceDate,
                                  );

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: SizedBox.expand(
                                      child: isBarChart
                                          ? buildBarChart(
                                              context,
                                              filteredEntries,
                                              tabType,
                                              referenceDate)
                                          : buildPieChart(
                                              context,
                                              badgeCountMap,
                                              tabType,
                                              referenceDate),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    'Morning',
                                    'Afternoon',
                                    'Evening',
                                    'Night'
                                  ].map((period) {
                                    final count = metricsTimes[period] ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Text(
                                        '$period : $count',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  'Morning',
                                  'Afternoon',
                                  'Evening',
                                  'Night'
                                ].map((period) {
                                  final count = metricsTimes[period] ?? 0;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      '$period : $count',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      )
                    ],
                  ),
                ),
              );
            })
          : const Center(
              child: Text('Add entries in Home to view the metrics.',
                  style: TextStyle(fontSize: 16)),
            ),
    );
  }

  void showBadgeLegend(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🚀  Earn Badges!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var entry in [
                      {
                        'asset': 'assets/badges/badge_0.svg', // grey
                        'label': '0 entries' // grey
                      },
                      {
                        'asset': 'assets/badges/badge_1.svg', // yellow
                        'label': '1–4 entries' // yellow
                      },
                      {
                        'asset': 'assets/badges/badge_2.svg', // green
                        'label': '5–9 entries' // green
                      },
                      {
                        'asset': 'assets/badges/badge_3.svg', // blue
                        'label': '10–14 entries' // blue
                      },
                      {
                        'asset': 'assets/badges/badge_4.svg', // purple
                        'label': '15–19 entries' // purple
                      },
                      {
                        'asset': 'assets/badges/badge_5.svg', // red
                        'label': '20+ entries' // red
                      },
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(entry['asset']!,
                                width: 36, height: 36),
                            const SizedBox(width: 20),
                            Text(
                              entry['label']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // calendar button to take to /today/ view on scroll
  void jumpToToday(DateTime anchor) {
    setState(() {
      switch (viewType) {
        case 'Day':
          referenceDate = DateTime(anchor.year, anchor.month, anchor.day);
          break;
        case 'Week':
          referenceDate = anchor.subtract(Duration(days: anchor.weekday - 1));
          break;
        case 'Month':
          referenceDate = DateTime(anchor.year, anchor.month);
          break;
        case 'Year':
          referenceDate = DateTime(anchor.year);
          break;
      }
    });
  }

  // to make the calendar icon disappear if the view is on /today/
  bool isOnTodayAnchor() {
    final now = DateTime.now();

    switch (viewType) {
      case 'Day':
        return referenceDate.year == now.year &&
            referenceDate.month == now.month &&
            referenceDate.day == now.day;

      case 'Week':
        final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
        return referenceDate.year == startOfThisWeek.year &&
            referenceDate.month == startOfThisWeek.month &&
            referenceDate.day == startOfThisWeek.day;

      case 'Month':
        return referenceDate.year == now.year &&
            referenceDate.month == now.month;

      case 'Year':
        return referenceDate.year == now.year;
    }
    return false;
  }
}
