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
import '../models/entry.dart';
import '../theme.dart';

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
    final dateEntries = ref.watch(dateEntriesProvider);
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final previousDates = dateEntries.keys
        .where((date) => date != todayDate)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final Map<String, List<String>> groupedByMonth = {};
    for (var date in previousDates) {
      final dt = DateTime.parse(date);
      final monthKey = DateFormat('yyyy-MM').format(dt);
      groupedByMonth.putIfAbsent(monthKey, () => []).add(date);
    }

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    return Scaffold(
      appBar: const CustomAppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
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
                  groupedByMonth: groupedByMonth,
                  dateEntries: dateEntries,
                  previousDates: previousDates,
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
                  onMonthToggle: (monthKey) {
                    setState(() {
                      monthVisibility[monthKey] =
                          !(monthVisibility[monthKey] ?? false);
                    });
                  },
                  expansionTileKeys: expansionTileKeys,
                  currentMonth: currentMonth,
                  ref: ref)
            ],
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
