// home_entries_list.dart, helper function to build entries for a single date on the homescreen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_entries_provider.dart';
import '../models/entry.dart';
import '../theme.dart';

// render all entries for a given date, non scrollable and compact
Widget buildEntriesForDate(WidgetRef ref, String date) {
  // watch provider so ui updates immediately on add/ remove
  final dateEntries = ref.watch(dateEntriesProvider);
  // entries may not exist for a date yet - no chip
  List<Entry>? entries = dateEntries[date];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      // render entries only when present
      if (entries != null && entries.isNotEmpty)
        ListView.builder(
          // prevent nested scroll conflicts inside parent scroll views
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            // reverse list so the newest entries appear first
            final reversedEntry = entries.reversed.toList()[index];
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 12, right: 0),
              // custom bullet + text using richtext for alignment control
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
              // lightweight minimal delete action on swipe
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon:
                    const Icon(Icons.remove, color: AppTheme.iconDeleteContent),
                onPressed: () {
                  // delegate deletion logic to provider
                  ref
                      .read(dateEntriesProvider.notifier)
                      .removeEntry(date, reversedEntry);
                },
              ),
            );
          },
        )
      else
        // empty state for date with no entries yet
        const Text("No entries yet."),
      const SizedBox(height: 8),
    ],
  );
}
