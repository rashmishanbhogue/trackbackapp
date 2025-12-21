// data_entries_provider.dart, state + persistnece layer for daily entries in the primary hive box

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/entry.dart';
import '../utils/hive_utils.dart';

// injected hive box provider, kept as a provider to make this notifier testable and decoupled
final hiveBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError(); // will be overridden in main() with the real hive box at runtime
});

// central source of truth for all screens but ideas - exposes a map of yyyy-mm-dd list of entries
final dateEntriesProvider =
    StateNotifierProvider<DateEntriesNotifier, Map<String, List<Entry>>>(
  (ref) {
    final box = ref.watch(hiveBoxProvider);
    return DateEntriesNotifier(box);
  },
);

class DateEntriesNotifier extends StateNotifier<Map<String, List<Entry>>> {
  final Box box;

  // notifier starts empty and immediately hydrates from primary hive
  DateEntriesNotifier(this.box) : super({}) {
    loadEntries();
  }

  // loads persisted entries from hive into memory - converts raw json strings back into Entry objects
  void loadEntries() {
    final stored = box.get('entries');
    // debugPrint('Raw from Hive: $stored');

    if (stored != null && stored is Map) {
      final parsed = Map<String, List<Entry>>.fromEntries(
        stored.entries.map((e) {
          final date = e.key as String;
          final rawList = e.value;

          // defensive if data shape is unexpected, return empty list
          if (rawList is! List) return MapEntry(date, <Entry>[]);

          final entries = rawList
              .map<Entry?>((item) {
                try {
                  if (item is String) {
                    // if item looks like a json object, parse it. normal path - stored json string
                    if (item.trim().startsWith('{')) {
                      final json = jsonDecode(item);
                      return Entry.fromJson(json);
                    } else {
                      // fallback for older or raw text entries. preserves text but resets label + timestamp
                      return Entry(
                          text: item, label: '', timestamp: DateTime.now());
                    }
                  } else {
                    return null;
                  }
                } catch (e) {
                  // swallow parsing errors to avoid crashing on corrupt data
                  return null;
                }
              })
              .whereType<Entry>()
              .toList(); // remove nulls

          return MapEntry(date, entries); // add parsed list to final map
        }),
      );
      state = parsed; // update state with loaded entries
    } else {
      state = {}; // no entries yet, first run
    }
  }

  // use storeLabelsInHive to store updated label counts
  Future<void> updateLabelCounts(Map<String, int> labelCounts) async {
    await storeLabelsInHive(labelCounts);
  }

  // use getLabelsFromHive to load previously stored label counts
  Future<Map<String, int>> getStoredLabelCounts() async {
    return await getLabelsFromHive();
  }

  // add a single entry under a date key - update both memory state and hive
  void addEntry(String date, Entry entry) {
    final updatedEntries = Map<String, List<Entry>>.from(state);

    updatedEntries.putIfAbsent(date, () => []); // create datelist if needed
    updatedEntries[date]!.add(entry); // add new entry to that date

    state = updatedEntries; // update state in memory

    // store as json strings in hive for compatibility
    final storedMap = updatedEntries.map(
      (key, value) => MapEntry(
        key,
        value.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
    );

    box.put('entries', storedMap); // save to hive
  }

  // remove a single entry by matching text + timestamp - avoid accidental deletion of similar entries
  void removeEntry(String date, Entry entry) {
    final updatedEntries = Map<String, List<Entry>>.from(state);

    if (updatedEntries.containsKey(date)) {
      // remove entry matching both text and timestamp
      updatedEntries[date]!.removeWhere(
          (e) => e.text == entry.text && e.timestamp == entry.timestamp);

      if (updatedEntries[date]!.isEmpty) {
        updatedEntries.remove(date); // remove dategroup if its empty
      }
    }

    state = updatedEntries;

    // store as json strings in hive
    final storedMap = updatedEntries.map(
      (key, value) => MapEntry(
        key,
        value.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
    );
    box.put('entries', storedMap); // save to hive
  }

  // remove all entries for a specific date - ysed by bulk delete flows
  void removeEntriesForDate(String date) {
    final updatedEntries = Map<String, List<Entry>>.from(state);

    updatedEntries.remove(date); // delete the entire dategroup

    state = updatedEntries;

    // store as json strings in hive
    final storedMap = updatedEntries.map(
      (key, value) => MapEntry(
        key,
        value.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
    );
    box.put('entries', storedMap); // save to hive
  }

  // replace tje entire entries map - used after ai labeling to persist updated labels in bulk
  void replaceAll(Map<String, List<Entry>> newEntries) {
    state = newEntries;

    // store each entry as json string before saving
    final storedMap = state.map(
      (key, value) => MapEntry(
        key,
        value.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
    );

    box.put('entries', storedMap);
  }
}
