// home_screen.dart, default note input screen, central hub to the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/date_entries_provider.dart';
import '../providers/ideas_dump_provider.dart';
import '../utils/home_dialog_utils.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_fab.dart';
// import '../widgets/badges_svg.dart';
import '../widgets/expandable_chips.dart';
import '../widgets/home_entries_list.dart';
import '../widgets/navbar.dart';
import '../widgets/older_expansion_chips.dart';
import '../widgets/responsive_screen.dart';
import '../models/entry.dart';
import '../models/idea_item.dart';
import '../theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  // keep draft input across bottom-nav tab switches
  // controller for the main /today/ inputfield
  late TextEditingController controller;
  // scroll controller for programmatic scrolling when expanding tiles
  final scrollController = ScrollController();
  // focusnode to track focus with FAB
  final FocusNode inputFocusNode = FocusNode();

  // track which date chip is expanded - index based sicn expansiontiles dont expose state directly
  int? expandedChipIndex;

  // month visiblity map for expandable month sections
  final Map<String, bool> monthVisibility = {};
  // key used to scroll expanded tiles into view
  final Map<String, GlobalKey> expansionTileKeys = {};
  // year visibility map for older entries
  final Map<String, bool> yearVisibility = {};

  @override
  bool get wantKeepAlive => true; // keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    controller.addListener(() {
      setState(
          () {}); // rebuild to keep FAB enabled/ disabled n sync with text input

      final text = controller.text;

      // multiline or long text input implies elaboration -> route to ideas flow
      final isMultiline = text.contains('\n');
      final isLong = text.length > 150;

      if (isMultiline || isLong) {
        // trigger expansion to ideas note editor
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // enable FAB only upon textfield input
    final hasText = controller.text.trim().isNotEmpty;

    // full date - entries map from provider
    final dateEntries = ref.watch(dateEntriesProvider);
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    // collect all past dates excluding today
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

    // group older dates by month yyyy-mm
    final Map<String, List<String>> groupedByMonth = {};
    for (final date in olderDates) {
      final dt = DateTime.parse(date);
      final monthKey = DateFormat('yyyy-MM').format(dt);
      groupedByMonth.putIfAbsent(monthKey, () => []).add(date);
    }

    final Map<String, Map<String, List<String>>> groupedByYear = {};

    groupedByMonth.forEach((monthKey, dates) {
      final parts = monthKey.split('-'); // yyyy-MM
      final year = parts[0];
      final month = parts[1];

      groupedByYear.putIfAbsent(year, () => {});
      groupedByYear[year]!.putIfAbsent(month, () => []);
      groupedByYear[year]![month]!.addAll(dates);
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      body: GestureDetector(
        // dismiss keyboard when tapping otuside inputs
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ResponsiveScreen(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            // sliver based layout to support mixed scrolling content
            child: CustomScrollView(controller: scrollController, slivers: [
              // today header + ideas icon
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Today", style: TextStyle(fontSize: 24)),
                      const Spacer(),
                      // buildBadge(dateEntries[todayDate]?.length ?? 0),
                      IconButton(
                          icon: const Icon(Icons.lightbulb,
                              size: 26, color: Colors.orangeAccent),
                          tooltip: 'Ideas',
                          onPressed: () {
                            // go to ideas via shell state - keeps bottom nav and avoids back stack
                            ref.read(shellPageProvider.notifier).state =
                                ShellPage.ideas;
                          })
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // main input for todays notes
              // lightweight capture - always visible, enter inserts newline, only FAB saves input
              SliverToBoxAdapter(
                child: TextField(
                  maxLines: null, // ideas note, enter -> newline
                  minLines: 1, // done task
                  controller: controller,
                  focusNode: inputFocusNode,
                  keyboardType: TextInputType.multiline,
                  textInputAction:
                      TextInputAction.newline, // do not submit on enter
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    // clear input icon to clear draft input without submitting
                    suffixIcon: hasText
                        ? Padding(
                            padding: const EdgeInsets.only(right: 10, left: 4),
                            child: InkResponse(
                              radius: 10,
                              onTap: () {
                                controller.clear();
                              },
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 0.8,
                                    color: isDark
                                        ? AppTheme.inputFillLight
                                        : AppTheme.inputFillDark,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 11,
                                  color: isDark
                                      ? AppTheme.inputFillLight
                                      : AppTheme.inputFillDark,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // lsit of todays entries
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return buildEntriesForDate(ref, todayDate);
                  },
                  childCount: 1,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // previous days section - older entries for /currentmonth/ only
              const SliverToBoxAdapter(
                child:
                    Text("Earlier this month", style: TextStyle(fontSize: 20)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              // expandable chips for current month only
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
                  showHomeDeleteDialog(context, date, ref);
                },
                onMonthToggle: (_) {}, // not used for current month
                expansionTileKeys: expansionTileKeys,
                currentMonth: currentMonthKey,
                ref: ref,
              ),

              // older entries secction
              if (olderDates.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(
                  child: Text("Older...", style: TextStyle(fontSize: 18)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                // nested year - month - date expansion
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
            ]),
          ),
        ),
      ),
      // fab saves only task-like input; ideas are handled elsewhere, enabled only if input exists in the textfield
      floatingActionButton: CustomFAB(
        onPressed: hasText
            ? () {
                final text = controller.text.trim();

                final isIdea = text.contains('\n') || text.length > 150;

                // guard - ideas should not be saved to home
                if (isIdea) {
                  ref.read(ideasDumpProvider.notifier).addIdea(
                      IdeaItem.newDraft(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          text: text,
                          colorValue: AppTheme.ideaColors.first.toARGB32()));

                  // reset home capture state after handoff
                  controller.clear();
                  inputFocusNode.unfocus();

                  // snackbar with the message and an option to route to view it
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: isDark
                          ? AppTheme.surfaceHighDark
                          : AppTheme.surfaceHighLight,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                      content: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Saved to Ideas',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(shellPageProvider.notifier).state =
                                  ShellPage.ideas;
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                            },
                            child: const Text(
                              'View',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.orangeAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  return;
                }

                // home entry for done tasks in the primary hivebox
                ref.read(dateEntriesProvider.notifier).addEntry(
                      todayDate,
                      Entry(
                        text: controller.text.trim(),
                        label: '',
                        timestamp: DateTime.now(),
                      ),
                    );
                controller.clear();
                inputFocusNode.unfocus();
              }
            : null,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
