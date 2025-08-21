// home_dialog_utils.dart, to

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_entries_provider.dart';

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
