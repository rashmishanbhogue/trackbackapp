// data_entries_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/entry.dart';
import '../utils/hive_utils.dart';

final hiveBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError(); // will be overridden in main()
});

final dateEntriesProvider =
    StateNotifierProvider<DateEntriesNotifier, Map<String, List<Entry>>>(
  (ref) {
    final box = ref.watch(hiveBoxProvider);
    return DateEntriesNotifier(box);
  },
);

class DateEntriesNotifier extends StateNotifier<Map<String, List<Entry>>> {
  final Box box;

  DateEntriesNotifier(this.box) : super({}) {
    loadEntries();
  }

  void loadEntries() {
    final stored = box.get('entries');
    if (stored != null && stored is Map) {
      final parsed = Map<String, List<Entry>>.fromEntries(
        stored.entries.map((e) {
          final date = e.key as String;
          final rawList = e.value;

          if (rawList is! List) return MapEntry(date, <Entry>[]);

          final entries = rawList
              .map<Entry?>((item) {
                try {
                  if (item is String) {
                    if (item.trim().startsWith('{')) {
                      final json = jsonDecode(item);
                      return Entry.fromJson(json);
                    } else {
                      return Entry(
                          text: item, label: '', timestamp: DateTime.now());
                    }
                  } else {
                    return null;
                  }
                } catch (e) {
                  return null;
                }
              })
              .whereType<Entry>()
              .toList(); // remove nulls

          return MapEntry(date, entries);
        }),
      );
      state = parsed;
    } else {
      state = {};
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

  void addEntry(String date, Entry entry) {
    final updatedEntries = Map<String, List<Entry>>.from(state);

    updatedEntries.putIfAbsent(date, () => []);
    updatedEntries[date]!.add(entry);

    state = updatedEntries;

    // store as json strings in hive
    final storedMap = updatedEntries.map(
      (key, value) => MapEntry(
        key,
        value.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
    );

    box.put('entries', storedMap);
  }

  void removeEntry(String date, Entry entry) {
    final updatedEntries = Map<String, List<Entry>>.from(state);

    if (updatedEntries.containsKey(date)) {
      updatedEntries[date]!.removeWhere(
          (e) => e.text == entry.text && e.timestamp == entry.timestamp);

      if (updatedEntries[date]!.isEmpty) {
        updatedEntries.remove(date);
      }
    }

    state = updatedEntries;

    box.put('entries', state);
  }

  void removeEntriesForDate(String date) {
    final updatedEntries = Map<String, List<Entry>>.from(state);

    updatedEntries.remove(date);

    state = updatedEntries;

    box.put('entries', state);
  }

  void replaceAll(Map<String, List<Entry>> newEntries) {
    state = newEntries;
    final storedMap = state.map(
      (key, value) => MapEntry(
        key,
        value.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
    );
    box.put('entries', storedMap);
  }
}
