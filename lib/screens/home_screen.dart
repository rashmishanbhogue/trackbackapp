// home_screen.dart, default note input screen on app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/date_entries_provider.dart';
import '../widgets/badges_svg.dart';
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
              ref.read(ThemeProvider.notifier).toggleTheme();
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
              SliverList(
                delegate: SliverChildListDelegate(
                  groupedByMonth.entries.expand((entry) {
                    final isCurrent = entry.key == currentMonth;
                    final monthYear = DateFormat('MMMM yyyy')
                        .format(DateTime.parse('${entry.key}-01'));

                    final List<Widget> widgets = [];

                    if (!isCurrent) {
                      monthVisibility.putIfAbsent(entry.key, () => false);

                      widgets.add(
                        TextButton(
                          onPressed: () {
                            setState(() {
                              monthVisibility[entry.key] =
                                  !(monthVisibility[entry.key] ?? false);
                            });
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
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.expand_more,
                                  size: 18,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final shouldShow =
                        isCurrent || (monthVisibility[entry.key] ?? false);

                    if (shouldShow) {
                      widgets.addAll(entry.value.map((date) {
                        final formattedDate = DateFormat('dd-MMM-yyyy')
                            .format(DateTime.parse(date));
                        final tileKey = expansionTileKeys.putIfAbsent(
                            date, () => GlobalKey());
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
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDeleteConfirmationDialog(
                                  context, date, ref);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey.shade100
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface
                                      : Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey.shade200
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  key: tileKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 16),
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light
                                                  ? Colors.black
                                                  : Colors.white70,
                                            ),
                                          ),
                                          const Expanded(
                                              child: SizedBox(width: 0)),
                                          buildBadge(count),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          expandedChipIndex =
                                              isExpanded ? null : index;
                                        });
                                        if (!isExpanded) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            final ctx = tileKey.currentContext;
                                            if (ctx != null) {
                                              final renderBox =
                                                  ctx.findRenderObject()
                                                      as RenderBox;
                                              final position = renderBox
                                                  .localToGlobal(Offset.zero)
                                                  .dy;
                                              final screenHeight =
                                                  MediaQuery.of(ctx)
                                                      .size
                                                      .height;
                                              final isTooLow =
                                                  position > screenHeight * 0.6;
                                              Scrollable.ensureVisible(
                                                ctx,
                                                duration: const Duration(
                                                    milliseconds: 400),
                                                curve: Curves.easeInOut,
                                                alignment:
                                                    isTooLow ? 0.05 : 0.1,
                                              );
                                            }
                                          });
                                        }
                                      },
                                    ),
                                    if (isExpanded)
                                      ...(dateEntries[date] ?? []).map((entry) {
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              expandedChipIndex = null;
                                            });
                                          },
                                          child: ListTile(
                                            title: Text(
                                              entry.text,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.light
                                                    ? Colors.black87
                                                    : Colors.white60,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
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
              ),
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
        backgroundColor: Colors.amber[700],
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
                icon: const Icon(Icons.remove, color: Colors.redAccent),
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
