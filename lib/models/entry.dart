// entry.dart, core data model for note entries only not ideas section

import 'package:hive/hive.dart';

part 'entry.g.dart'; // generate the hvie typeadapter code

// hive backed immunity entry model. each entry represents one atomic note written by the user
@HiveType(
    typeId:
        0) // unique identifier for the type, must remain stable once shipped
class Entry {
  // raw text content written by the user
  @HiveField(0)
  final String text;

  // empty during initial capture, populated later by aimetrics
  @HiveField(1)
  final String label;

  // exact creation timestamp for filtering
  @HiveField(2)
  final DateTime timestamp;

  Entry({
    required this.text,
    required this.label,
    required this.timestamp,
  });

  // serialise entry to json
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'label': label,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // reconstruct entry from stored json
  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        text: json['text'],
        label: json['label'],
        timestamp: DateTime.parse(json['timestamp']),
      );

  // immutable copy helper, used when updating labels or timestamps without mutating state
  Entry copyWith({String? text, DateTime? timestamp, String? label}) {
    return Entry(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
    );
  }
}
