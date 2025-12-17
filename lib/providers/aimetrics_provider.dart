// ai_metrics_provider.dart, to manage state and logic for ai-based productivity label generation and refresh

import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../services/groq_service.dart';

// handle the ai metrics logic and notifies listeners when data changes
class AiMetricsProvider extends ChangeNotifier {
  // track whether a background process is running - used to show loading indicators
  bool isLoading = false;

  // list to store entries after they have been classified by groq
  List<Entry> classifiedEntries = [];

  // store time of last update to classified entries
  DateTime? lastUpdated;

  // method to refresh classification - triggers loading state calls, calls classification,
  // updates internal state and notifies listener about the changes
  // used when user reruns the classification
  Future<void> refreshAndClassifyEntries(List<Entry> allEntries) async {
    // mark as loading before the api call
    isLoading = true;
    // tell ui to update and reflect the loading state
    notifyListeners();

    // perform classification using groq and wait for the result
    final labelledEntries = await classifyEntriesWithGroq(allEntries);
    // store the newly classified entries
    classifiedEntries = labelledEntries;
    // update the last updated timestamp
    lastUpdated = DateTime.now();

    // mark loading as complete
    isLoading = false;
    // notify the ui again to reflect new data and turn off the loader
    notifyListeners();
  }

  // helper method to perform actual classification call to groq
  // separated as method to clean up the logic and make it testable
  Future<List<Entry>> classifyEntriesWithGroq(List<Entry> entries) async {
    // call the external groq service
    return await GroqService.classify(entries);
  }

  // method to let the ui update the classification data manually
  // useful when editing labels or syncing with external updates
  void updateClassificationLabels(List<Entry> updatedEntries) {
    // overwrite current classified list
    classifiedEntries = updatedEntries;
    // update timestamp
    lastUpdated = DateTime.now();
    // notify ui of the update
    notifyListeners();
  }
}
