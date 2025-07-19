// hive_seeder.dart
// seeder file with fake data to populate for the purpose of testing
// and when the AVD data gets wiped

import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import '../models/entry.dart';

Future<void> runHiveSeeder() async {
  final box = await Hive.openBox('trackback');

  // if entries already exist, try to read and decode them
  if (box.containsKey('entries')) {
    final raw = box.get('entries') as Map;
    final entries = raw.map<String, List<Entry>>((key, value) {
      return MapEntry(
        key.toString(),
        (value as List).map<Entry>((e) {
          if (e is Entry) {
            return e;
          } else if (e is Map) {
            return Entry.fromJson(Map<String, dynamic>.from(e));
          } else if (e is String) {
            // try decoding from string if stored as JSON
            try {
              final decoded = jsonDecode(e);
              if (decoded is Map) {
                return Entry.fromJson(Map<String, dynamic>.from(decoded));
              } else {
                throw Exception('Decoded JSON is not a map: $decoded');
              }
            } catch (err) {
              throw Exception('Failed to decode string entry: $e');
            }
          } else {
            throw Exception('Invalid entry format: $e');
          }
        }).toList(),
      );
    });

    // debugPrint('Loaded entries from box. Days available: ${entries.keys}');
  }

  final faker = Faker();
  final random = Random();
  final now = DateTime.now();
  final Map<String, List<Entry>> grouped = {};
  final labels = [
    'Productive',
    'Maintenance',
    'Wellbeing',
    'Leisure',
    'Social',
    'Idle'
  ];

  // choose 30 unique days over the past 90 days
  final uniqueDays = <String>{};
  while (uniqueDays.length < 30) {
    final date = now.subtract(Duration(days: random.nextInt(90)));
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    uniqueDays.add(dateKey);
  }

  // for each selected day, assign random number of entries
  // values are designed to test badge levels and chart variety
  for (final dateKey in uniqueDays) {
    final entryCount = switch (random.nextInt(100)) {
      < 10 => 0, // 10% chance of 0 entries
      < 40 => 1, // 30% chance of 1 entry
      < 70 => 3 + random.nextInt(3), // 30% chance of 3-5 entries
      < 90 => 6 + random.nextInt(4), // 20% chance of 6-9 entries
      _ => 15 + random.nextInt(7), // 10% chance of 15-21 entries (edge test)
    };

    for (int i = 0; i < entryCount; i++) {
      final date = DateTime.parse(dateKey).add(
          Duration(hours: random.nextInt(24), minutes: random.nextInt(60)));

      final entry = Entry(
          text: faker.lorem.sentence(),
          label: labels[random.nextInt(labels.length)],
          timestamp: date);

      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
  }

  // convert to JSON strings like the provider expects
  final storedMap = grouped.map((key, value) => MapEntry(
        key,
        value.map((e) => jsonEncode(e.toJson())).toList(),
      ));

  // debugPrint("Putting entries into Hive...");
  // debugPrint("storedMap keys: ${storedMap.keys}");
  // debugPrint("Sample value for first key: ${storedMap.values.first}");

  await box.clear(); // optional: clear old data before seeding
  await box.put('entries', storedMap);
  await box.flush(); // force write to disk

  // debugPrint("box.keys after put: ${box.keys}");

  // after writing to the hive box, immediately try to read back the 'entries' key
  // this is a sanity check to make sure the write actually succeeded
  // if rawConfirm is null, it means either the write failed silently or something corrupted the data
  // throwing an exception here makes it clear there is a critical issue with data persistence
  final rawConfirm = box.get('entries');

  // debugPrint("rawConfirm after put: $rawConfirm");

  if (rawConfirm == null) {
    throw Exception('No entries found in Hive box during confirmation.');
  }

  // attempt to decode stored data to confirm it is valid
  final confirmMap = rawConfirm as Map;

  final confirm = confirmMap.map<String, List<Entry>>((key, value) {
    return MapEntry(
      key.toString(),
      (value as List).map<Entry>((e) {
        try {
          final decoded = jsonDecode(e); // decode JSON string to map
          return Entry.fromJson(Map<String, dynamic>.from(decoded));
        } catch (err) {
          throw Exception('Failed to decode entry during confirmation: $e');
        }
      }).toList(),
    );
  });

  // debugPrint("Confirm read after write: ${confirm.keys}");

  // debugPrint('Seeder completed. Box keys: ${box.keys}');
  // debugPrint("Box path: ${box.path}");
}
