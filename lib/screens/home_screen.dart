// home_screen.dart, default note input screen on app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../widgets/badges_svg.dart';
import '../widgets/expandable_chips.dart';
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
      appBar: AppBar(
        title: const Text('TrackBack'),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
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
      floatingActionButton: FloatingActionButton(
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

Widget buildEntriesForDate(WidgetRef ref, String date) {
  final dateEntries = ref.watch(dateEntriesProvider);
  List<Entry>? entries = dateEntries[date];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      if (entries != null && entries.isNotEmpty)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final reversedEntry = entries.reversed.toList()[index];
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 12, right: 0),
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '•    ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    TextSpan(
                      text: reversedEntry.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon:
                    const Icon(Icons.remove, color: AppTheme.iconDeleteContent),
                onPressed: () {
                  ref
                      .read(dateEntriesProvider.notifier)
                      .removeEntry(date, reversedEntry);
                },
              ),
            );
          },
        )
      else
        const Text("No entries yet."),
      const SizedBox(height: 8),
    ],
  );
}

Widget buildBadge(int count) {
  return BadgesSVG.getBadge(count);
}

Future<bool?> showDeleteConfirmationDialog(
    BuildContext context, String date, WidgetRef ref) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Entries?'),
        content: const Text(
            'Are you sure you want to delete all entries for this date?'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(dateEntriesProvider.notifier).removeEntriesForDate(date);
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
