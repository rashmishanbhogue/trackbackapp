// home_dialog_utils.dart, to handle the deletion dialog box for expansion tile swipe delete

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_entries_provider.dart';
import '../theme.dart';

// show a confirmation dilaog before deleting all entries for a given date
// widgetref is passed instead of context lookup - deletion logic stays provider driven. dialog remains stateless and reusable
Future<bool?> showDeleteConfirmationDialog(
    BuildContext context, String date, WidgetRef ref) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Delete Entries?',
          style: TextStyle(fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to delete all entries for this date?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          // destructive action
          TextButton(
            onPressed: () {
              // delete entire date group from provider and hive
              ref.read(dateEntriesProvider.notifier).removeEntriesForDate(date);
              // return confirmation result to caller
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.iconDeleteContent,
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          // non destructive cancel action
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      );
    },
  );
}
