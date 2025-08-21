// home_entries_list.dart, to

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_entries_provider.dart';
import '../models/entry.dart';
import '../theme.dart';

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
