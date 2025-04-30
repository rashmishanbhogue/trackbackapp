// entry.dart

import 'dart:convert';
import 'package:hive/hive.dart';

part 'entry.g.dart'; // generate the adapter code

@HiveType(typeId: 0) // unique identifier for the type
class Entry {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final DateTime timestamp;

  Entry({
    required this.text,
    required this.label,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'label': label,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        text: json['text'],
        label: json['label'],
        timestamp: DateTime.parse(json['timestamp']),
      );

  Entry copyWith({String? text, DateTime? timestamp, String? label}) {
    return Entry(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
    );
  }
}
