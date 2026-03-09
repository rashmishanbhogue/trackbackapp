// groq_service.dart, to handlethe external communication with groq api

import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/entry.dart';

// a service class wtih a static method to classify a list of entries using the groq api
class GroqService {
  // send request to the groq api
  // return the same list of entries, with a label each
  static Future<List<Entry>> classify(List<Entry> entries) async {
    // load api from .env
    final apiKey = dotenv.env['GROQ_API_KEY'];
    // debugPrint("GROQ API KEY PRESENT → ${apiKey != null && apiKey.isNotEmpty}");

    // if they key isnt found, skip classification and return original entries
    if (apiKey == null || apiKey.isEmpty) {
      return entries;
    }

    // base url for groq's chat completion endpoint
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    // prepare authorisation and content headers
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // list to store the updated classified entries
    List<Entry> updatedEntries = [];

    // loop through each entry to classify them one by one
    for (final entry in entries) {
      // debugPrint("GROQ REQUEST TEXT → ${entry.text}");
      // construct the request payload for classifying this specific entry
      final body = jsonEncode({
        'model': 'llama-3.3-70b-versatile', // model name
        'messages': [
          {
            'role': 'system',
            'content': '''
You are a strict text classifier.

Classify the user's activity into ONE of these categories:

Productive
Maintenance
Wellbeing
Leisure
Social
Idle

Definitions:

Productive
Work, studying, building, coding, writing, learning, planning, career-related activity.

Maintenance
Necessary life upkeep: cleaning, cooking, groceries, errands, commuting, paying bills, admin tasks.

Wellbeing
Physical or mental health: exercise, meditation, therapy, journaling, resting intentionally.

Leisure
Entertainment or hobbies: watching shows, gaming, reading for fun, music, creative hobbies.

Social
Interactions with other people: chatting, calls, meeting friends, family time.

Idle
Passive, unintentional, or low-engagement activity: scrolling, procrastinating, doing nothing, waiting.

Examples:
"cleaned kitchen" → Maintenance
"coding flutter app" → Productive
"gym workout" → Wellbeing
"watching netflix" → Leisure
"chatting with friend" → Social
"scrolling instagram" → Idle

Rules:
- Return ONLY the category name.
- Do NOT explain.
- Do NOT add punctuation.
- If uncertain, return Idle.
'''
          },
          {
            'role': 'user',
            'content':
                'Classify this text:\n"${entry.text}"', // user's text input
          }
        ],
        'temperature': 0.0, // deterministic output, no variations
      });

      try {
        // send the post request to groq
        final response =
            await http.post(Uri.parse(url), headers: headers, body: body);

        // parse and validate the response
        if (response.statusCode == 200) {
          // debugPrint("GROQ STATUS → ${response.statusCode}");
          // debugPrint("GROQ RAW RESPONSE → ${response.body}");
          final data = jsonDecode(response.body);
          final choices = data['choices'];

          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']['content']?.trim();

            // debugPrint("GROQ PARSED LABEL → $content");

            final normalized =
                content?.replaceAll('.', '').replaceAll('"', '').trim();

            // debugPrint("GROQ PARSED LABEL → $normalized");

            // // add the entry with returned label if valid
            // if (content != null &&
            //     [
            //       'Productive',
            //       'Maintenance',
            //       'Wellbeing',
            //       'Leisure',
            //       'Social',
            //       'Idle'
            //     ].contains(content)) {
            //   updatedEntries.add(entry.copyWith(label: content));
            //   continue;
            // }
            // debugPrint("GROQ LABEL NOT IN LIST → $content");
            if (normalized != null &&
                [
                  'Productive',
                  'Maintenance',
                  'Wellbeing',
                  'Leisure',
                  'Social',
                  'Idle'
                ].contains(normalized)) {
              updatedEntries.add(entry.copyWith(label: normalized));
              continue;
            }
            // debugPrint("GROQ LABEL NOT IN LIST → $normalized");
          }
        }
      } catch (e) {
        // handle errors gracefully
        // debugPrint('Error classifying entry: ${entry.text}, Error: $e');
      }

      // fallback - add entry with label 'Idle' if anything fails
      // debugPrint("GROQ FALLBACK → Idle for text: ${entry.text}");
      updatedEntries.add(entry.copyWith(label: 'Idle'));
    }

    // return the final list of labelled entries
    return updatedEntries;
  }

  // helper method to convert string to list<entry> for classify method
  static Future<String> classifySingleText(String text) async {
    final dummyEntry = Entry(text: text, label: '', timestamp: DateTime.now());
    final results = await classify([dummyEntry]);
    return results.first.label;
  }
}
