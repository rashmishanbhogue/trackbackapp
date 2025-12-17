// home_screen.dart, default note input screen on app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/date_entries_provider.dart';
import '../utils/home_dialog_utils.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_fab.dart';
import '../widgets/badges_svg.dart';
import '../widgets/expandable_chips.dart';
import '../widgets/home_entries_list.dart';
import '../widgets/older_expansion_chips.dart';
import '../widgets/responsive_screen.dart';
import '../models/entry.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  late TextEditingController controller;
  final scrollController = ScrollController();

  int? expandedChipIndex;

  final Map<String, bool> monthVisibility = {};
  final Map<String, GlobalKey> expansionTileKeys = {};

  final Map<String, bool> yearVisibility = {};

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateEntries = ref.watch(dateEntriesProvider);
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    final allPreviousDates = dateEntries.keys
        .where((date) => date != todayDate)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // current month only (for HomeExpansionTiles)
    final currentMonthDates = allPreviousDates.where((date) {
      final monthKey = DateFormat('yyyy-MM').format(DateTime.parse(date));
      return monthKey == currentMonthKey;
    }).toList();

    // older than current month (for OlderExpansionSliver)
    final olderDates = allPreviousDates.where((date) {
      final monthKey = DateFormat('yyyy-MM').format(DateTime.parse(date));
      return monthKey != currentMonthKey;
    }).toList();

    final Map<String, List<String>> groupedByMonth = {};
    for (final date in olderDates) {
      final dt = DateTime.parse(date);
      final monthKey = DateFormat('yyyy-MM').format(dt);
      groupedByMonth.putIfAbsent(monthKey, () => []).add(date);
    }
    // for (var date in previousDates) {
    //   final dt = DateTime.parse(date);
    //   final monthKey = DateFormat('yyyy-MM').format(dt);
    //   groupedByMonth.putIfAbsent(monthKey, () => []).add(date);
    // }

    final Map<String, Map<String, List<String>>> groupedByYear = {};

    groupedByMonth.forEach((monthKey, dates) {
      final parts = monthKey.split('-'); // yyyy-MM
      final year = parts[0];
      final month = parts[1];

      groupedByYear.putIfAbsent(year, () => {});
      groupedByYear[year]!.putIfAbsent(month, () => []);
      groupedByYear[year]![month]!.addAll(dates);
    });

    // groupedByMonth.forEach((monthKey, dates) {
    //   final parts = monthKey.split('-'); // yyyy-MM
    //   final year = parts[0];
    //   final month = parts[1];

    //   groupedByYear.putIfAbsent(year, () => {});
    //   groupedByYear[year]!.putIfAbsent(month, () => []);
    //   groupedByYear[year]![month]!.addAll(dates);
    // });

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    return Scaffold(
      appBar: const CustomAppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ResponsiveScreen(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomScrollView(controller: scrollController, slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Today", style: TextStyle(fontSize: 24)),
                      const Spacer(),
                      buildBadge(dateEntries[todayDate]?.length ?? 0),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: TextField(
                  controller: controller,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(dateEntriesProvider.notifier).addEntry(
                            todayDate,
                            Entry(
                              text: value.trim(),
                              label: '',
                              timestamp: DateTime.now(),
                            ),
                          );
                      controller.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return buildEntriesForDate(ref, todayDate);
                  },
                  childCount: 1,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: Text("Previous Days", style: TextStyle(fontSize: 20)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              HomeExpansionTiles(
                groupedByMonth: {
                  currentMonthKey: currentMonthDates,
                },
                dateEntries: dateEntries,
                previousDates: currentMonthDates,
                monthVisibility: monthVisibility,
                expandedChipIndex: expandedChipIndex,
                onChipTap: (index) {
                  setState(() {
                    expandedChipIndex = index;
                  });
                },
                onDelete: (date) {
                  showDeleteConfirmationDialog(context, date, ref);
                },
                onMonthToggle: (_) {}, // not used for current month
                expansionTileKeys: expansionTileKeys,
                currentMonth: currentMonthKey,
                ref: ref,
              ),
              if (olderDates.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(
                  child: Text("Older...", style: TextStyle(fontSize: 18)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                OlderExpansionSliver(
                  groupedbyYear: groupedByYear,
                  dateEntries: dateEntries,
                  previousDates: olderDates,
                  yearVisibility: yearVisibility,
                  monthVisibility: monthVisibility,
                  expandedChipIndex: expandedChipIndex,
                  onChipTap: (index) {
                    setState(() {
                      expandedChipIndex = index;
                    });
                  },
                  onYearToggle: (year) {
                    setState(() {
                      yearVisibility[year] = !(yearVisibility[year] ?? false);
                    });
                  },
                  onMonthToggle: (monthKey) {
                    setState(() {
                      monthVisibility[monthKey] =
                          !(monthVisibility[monthKey] ?? false);
                    });
                  },
                  expansionTileKeys: expansionTileKeys,
                  ref: ref,
                  isDark: isDark,
                ),
              ],

              // HomeExpansionTiles(
              //     groupedByMonth: groupedByMonth,
              //     dateEntries: dateEntries,
              //     previousDates: previousDates,
              //     monthVisibility: monthVisibility,
              //     expandedChipIndex: expandedChipIndex,
              //     onChipTap: (index) {
              //       setState(() {
              //         expandedChipIndex = index;
              //       });
              //     },
              //     onDelete: (date) {
              //       showDeleteConfirmationDialog(context, date, ref);
              //     },
              //     onMonthToggle: (monthKey) {
              //       setState(() {
              //         monthVisibility[monthKey] =
              //             !(monthVisibility[monthKey] ?? false);
              //       });
              //     },
              //     expansionTileKeys: expansionTileKeys,
              //     currentMonth: currentMonth,
              //     ref: ref)
            ]),
          ),
        ),
      ),
      floatingActionButton: CustomFAB(
        onPressed: () {
          if (controller.text.trim().isNotEmpty) {
            ref.read(dateEntriesProvider.notifier).addEntry(
                  todayDate,
                  Entry(
                    text: controller.text.trim(),
                    label: '',
                    timestamp: DateTime.now(),
                  ),
                );
            controller.clear();
            FocusScope.of(context).unfocus();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
