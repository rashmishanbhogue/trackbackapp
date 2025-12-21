// idea_item.dart, data model for the ideas_dump hivebox and section

import 'idea_task.dart';

class IdeaItem {
  // unique id used as hive key
  final String id;
  // optional title
  final String title;
  // main free form idea text
  final String text;
  // stored as int to keep model hive and json friendly - convert to color only at ui layer
  final int colorValue;
  // manual ordering index used by masonry grid - lower order, higher placement
  final int order;
  // creation timestamp - does not change
  final DateTime createdAt;
  // last updated timestamp for edits and sorting
  final DateTime updatedAt;
  // optional checklist for future - linked to idea
  final List<IdeaTask> tasks;

  IdeaItem(
      {required this.id,
      required this.title,
      required this.text,
      required this.colorValue,
      required this.order,
      required this.createdAt,
      required this.updatedAt,
      this.tasks = const []});

  // ensure only changed fields are replaced
  IdeaItem copyWith({
    String? title,
    String? text,
    int? colorValue,
    int? order,
    DateTime? updatedAt,
    List<IdeaTask>? tasks,
  }) {
    return IdeaItem(
        id: id,
        title: title ?? this.title,
        text: text ?? this.text,
        colorValue: colorValue ?? this.colorValue,
        order: order ?? this.order,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tasks: tasks ?? this.tasks);
  }

  // serialise for hive storage, stored as iso strings for portability
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'colorValue': colorValue,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  // deserialise from hive and json, defaults used to avoid crashes on older data
  factory IdeaItem.fromJson(Map<String, dynamic> json) => IdeaItem(
        id: json['id'],
        title: json['title'] ?? '',
        text: json['text'] ?? '',
        colorValue: json['colorValue'],
        order: json['order'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        tasks: (json['tasks'] as List? ?? [])
            .map((e) => IdeaTask.fromJson(e))
            .toList(),
      );

  // convenience factory for new unsorted drafts
  // used when creating a new idea before provider assigns order
  factory IdeaItem.newDraft({
    required String id,
    String title = '',
    required String text,
    required int colorValue,
  }) {
    return IdeaItem(
      id: id,
      title: title,
      text: text,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      order:
          -1, // placeholder, provider will fix this by recalculating correct order
    );
  }
}
