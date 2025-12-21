// idea_task.dart, task model attached to an idea item, for future task based idea expansions

class IdeaTask {
  // unique task id for persistence and updates
  final String id;
  // task description
  final String text;
  // whether the task has been started - separate from completion for future state expansion
  final bool isStarted;

  IdeaTask({required this.id, required this.text, this.isStarted = false});

  // serialise for storage in hive, json
  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'isStarted': isStarted};

  // deserialise with safe defaults for backward compatibility
  factory IdeaTask.fromJson(Map<String, dynamic> json) => IdeaTask(
      id: json['id'],
      text: json['text'],
      isStarted: json['isStarted'] ?? false);
}
