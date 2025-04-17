import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'providers/theme_provider.dart';
import 'providers/date_entries_provider.dart';
import 'theme.dart';
import 'widgets/badges_svg.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateEntries = ref.watch(dateEntriesProvider);
    final controller = TextEditingController();
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackBack'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              ref.read(ThemeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: CustomScrollView(
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
              SliverToBoxAdapter(child: const SizedBox(height: 10)),

              SliverToBoxAdapter(
                child: TextField(
                  controller: controller,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref
                          .read(dateEntriesProvider.notifier)
                          .addEntry(todayDate, value.trim());
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

              SliverToBoxAdapter(child: const SizedBox(height: 20)),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return buildEntriesForDate(ref, todayDate);
                  },
                  childCount: 1,
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(
                child:
                    const Text("Previous Days", style: TextStyle(fontSize: 20)),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),

              // sorted previous entries with latest date on top
              // needn't have an entry for each date on the calendar
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final previousDates = dateEntries.keys
                        .where((date) => date != todayDate)
                        .toList()
                      ..sort((a, b) => b.compareTo(a)); // newest entry first

                    if (index >= previousDates.length) return null;

                    final previousDate = previousDates[index];
                    int count = dateEntries[previousDate]?.length ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.1)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ExpansionTile(
                        title: Text(previousDate),
                        trailing: buildBadge(count),
                        children:
                            (dateEntries[previousDate] ?? []).map((entry) {
                          return ListTile(
                            title: Text(entry),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  childCount: dateEntries.keys
                      .where((date) => date != todayDate)
                      .length,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.text.trim().isNotEmpty) {
            ref
                .read(dateEntriesProvider.notifier)
                .addEntry(todayDate, controller.text.trim());
            controller.clear();
            FocusScope.of(context).unfocus();
          }
        },
        backgroundColor: Colors.amber[700],
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget buildEntriesForDate(WidgetRef ref, String date) {
    final dateEntries = ref.watch(dateEntriesProvider);
    List<String>? entries = dateEntries[date];

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
                        text: entries[index],
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
                        .removeEntry(date, entries[index]);
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
}
