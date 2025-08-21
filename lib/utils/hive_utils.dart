// hive_utils.dart, helper methods to store/retrieve data from hive and flatten entries

import 'package:hive/hive.dart';
import '../models/entry.dart';

Future<void> storeLabelsInHive(Map<String, int> labelCounts) async {
  final box = await Hive.openBox('labelsBox');
  await box.put('labels', labelCounts);
}

Future<Map<String, int>> getLabelsFromHive() async {
  final box = await Hive.openBox('labelsBox');
  final data = box.get('labels');
  if (data != null) {
    return Map<String, int>.from(data);
  }
  return {};
}

Future<void> clearStoredLabels() async {
  final box = await Hive.openBox('labelsBox');
  await box.delete('labels');
}

// store lastupdated timestamp in hive
Future<void> storeLastUpdatedInHive(DateTime timestamp) async {
  final box = await Hive.openBox('settings'); // use an appropriate box name
  await box.put('lastUpdated',
      timestamp.toIso8601String()); // save the timestamp in ISO format
}

// retrieve lastupdated timestamp from hive
Future<DateTime?> getLastUpdatedFromHive() async {
  final box = await Hive.openBox('settings');
  final storedTimestamp = box.get('lastUpdated');
  if (storedTimestamp != null) {
    return DateTime.parse(
        storedTimestamp); // convert from ISO string to DateTime
  }
  return null; // null if not found
}

// flatten Map<String, List<Entry>> to List<Entry>
List<Entry> flattenEntries(Map<String, List<Entry>> dateEntriesMap) {
  return dateEntriesMap.values.expand((list) => list).toList();
}
