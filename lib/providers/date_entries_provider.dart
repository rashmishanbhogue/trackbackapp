import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

final dateEntriesProvider =
    StateNotifierProvider<DateEntriesNotifier, Map<String, List<String>>>(
  (ref) => DateEntriesNotifier(),
);

class DateEntriesNotifier extends StateNotifier<Map<String, List<String>>> {
  DateEntriesNotifier() : super({}) {
    initialize();
  }

  late Box box;

  Future<void> initialize() async {
    box = await Hive.openBox('trackback');
    loadEntries();
  }

  void loadEntries() {
    final storedData = box.get('entries', defaultValue: {});
    if (storedData is Map) {
      state = Map<String, List<String>>.from(storedData.map((key, value) =>
          MapEntry(key, List<String>.from(value as List<dynamic>))));
    }
  }

  void addEntry(String date, String entry) {
    final updatedEntries = Map<String, List<String>>.from(state);

    if (!updatedEntries.containsKey(date)) {
      updatedEntries[date] = [];
    }

    updatedEntries[date]!.add(entry);

    state = updatedEntries;
    box.put('entries', state);
  }

  void removeEntry(String date, String entry) {
    final updatedEntries = Map<String, List<String>>.from(state);

    if (updatedEntries.containsKey(date)) {
      updatedEntries[date]!.remove(entry);
      if (updatedEntries[date]!.isEmpty) {
        updatedEntries.remove(date);
      }
    }

    state = updatedEntries;
    box.put('entries', state);
  }

  void removeEntriesForDate(String date) {
    final updatedEntries = Map<String, List<String>>.from(state);

    updatedEntries.remove(date);

    state = updatedEntries;
    box.put('entries', state);
  }
}
