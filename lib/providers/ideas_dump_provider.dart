// ideas_dump_provider.dart, state and persistence layer for ideas, to manage loading, ordering, updates, and hive persistence

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/idea_item.dart';
import '../theme.dart';

// public provider for the ordered list of idea items
final ideasDumpProvider =
    StateNotifierProvider<IdeasDumpNotifier, List<IdeaItem>>((ref) {
  return IdeasDumpNotifier();
});

class IdeasDumpNotifier extends StateNotifier<List<IdeaItem>> {
  IdeasDumpNotifier() : super([]) {
    // async init is triggered from constructor to ensure ideas are loaded as soon as provider is created
    init();
  }

  // raw hive box to store ideas as json strings keyed by idea id
  late Box box;

  // seeded prompts shown on first install/ empty state to show the section intent
  static const defaultIdeaPrompts = [
    'Capture half-formed thoughts before they disappear.',
    'Ideas don\'t need structure. Just dump them.',
    'Random product idea: mood-based journaling.',
    'Write now. Organize later.',
  ];

  Future<void> init() async {
    // open or create hive box
    box = await Hive.openBox('ideas_dump');

    // dev only - clear hive
    // await box.clear();

    // seed default prompts only once when box is empty
    if (box.isEmpty) {
      for (int i = 0; i < defaultIdeaPrompts.length; i++) {
        final text = defaultIdeaPrompts[i];

        final idea = IdeaItem(
          // microsecond timestamp + hash to ensure uniqueness
          id: DateTime.now().microsecondsSinceEpoch.toString() +
              text.hashCode.toString(),
          title: '',
          text: text,
          // rotate through predefined pastel palette
          colorValue:
              AppTheme.ideaColors[i % AppTheme.ideaColors.length].toARGB32(),
          // initial order matches insertion order
          order: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        box.put(idea.id, jsonEncode(idea.toJson()));
      }
    }

    // hydrate inmemory state from hive
    load();
  }

  void load() {
    // read all stored ideas and deserialise
    final raw = box.toMap().values.cast<String>();
    final ideas = raw.map((e) => IdeaItem.fromJson(jsonDecode(e))).toList()
      // ensure stable ordering for ui
      ..sort((a, b) => a.order.compareTo(b.order));

    // normalise order indices - guard against corruption or legacy data mismatches
    for (int i = 0; i < ideas.length; i++) {
      if (ideas[i].order != i) {
        final fixed = ideas[i].copyWith(order: i);
        ideas[i] = fixed;
        box.put(fixed.id, jsonEncode(fixed.toJson()));
      }
    }

    // publish final ordered list
    state = ideas;
  }

  void addIdea(IdeaItem idea) {
    // shift all existing ideas down by one
    final updated = [for (final i in state) i.copyWith(order: i.order + 1)];

    // new idea to be added on top left always
    final newIdea = idea.copyWith(order: 0);

    // persist new idea first
    box.put(newIdea.id, jsonEncode(newIdea.toJson()));

    // persist updated order for existing ideas
    for (final i in updated) {
      box.put(i.id, jsonEncode(i.toJson()));
    }
    // update state so ui rebuilds immediately
    state = [newIdea, ...updated];
  }

  void updateIdea(IdeaItem idea) {
    // overwrite existing idea data without changing order
    box.put(idea.id, jsonEncode(idea.toJson()));
    // replace in state list
    state = [for (final i in state) i.id == idea.id ? idea : i];
  }

  void removeIdea(String id) {
    // delete from persistence
    box.delete(id);
    // remove from inmemory state
    state = state.where((i) => i.id != id).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    // local copy to avoid mutating state directly
    final items = [...state];

    // account for removal offset when dragging downwards
    if (newIndex > oldIndex) newIndex -= 1;

    // move item in list
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    // rebuild list with normalised order values
    final reordered = <IdeaItem>[];
    for (int i = 0; i < items.length; i++) {
      reordered.add(items[i].copyWith(order: i));
    }

    // persist updated ordering
    for (final idea in reordered) {
      box.put(idea.id, jsonEncode(idea.toJson()));
    }

    // publish reordered list
    state = reordered;
  }
}
