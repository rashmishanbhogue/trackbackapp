// item_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final itemProvider = StateNotifierProvider<ItemNotifier, List<String>>((ref) {
  return ItemNotifier();
});

class ItemNotifier extends StateNotifier<List<String>> {
  ItemNotifier() : super([]) {
    initialize();
  }

  late Box box;

  Future<void> initialize() async {
    box = await Hive.openBox('trackback');
    loadItems();
  }

  void loadItems() {
    state = List<String>.from(box.get('items', defaultValue: []));
  }

  void addItem(String item) {
    state = [...state, item];
    box.put('items', state);
  }

  void removeItem(String item) {
    state = state.where((i) => i != item).toList();
    box.put('items', state);
  }
}
