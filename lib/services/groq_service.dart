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
      // construct the request payload for classifying this specific entry
      final body = jsonEncode({
        'model': 'llama3-8b-8192', // model name
        'messages': [
          {
            'role': 'system',
            'content': '''
You are a strict classifier. Return only one label from this list, nothing else:

Productive, Maintenance, Wellbeing, Leisure, Social, Idle.

Do not return anything outside this list, no extra text, no explanations.
If uncertain, return "Idle".
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
          final data = jsonDecode(response.body);
          final choices = data['choices'];

          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']['content']?.trim();

            // add the entry with returned label if valid
            if (content != null &&
                [
                  'Productive',
                  'Maintenance',
                  'Wellbeing',
                  'Leisure',
                  'Social',
                  'Idle'
                ].contains(content)) {
              updatedEntries.add(entry.copyWith(label: content));
              continue;
            }
          }
        }
      } catch (e) {
        // handle errors gracefully
        debugPrint('Error classifying entry: ${entry.text}, Error: $e');
      }

      // fallback - add entry with label 'Uncategorised' if anything fails
      updatedEntries.add(entry.copyWith(label: 'Uncategorised'));
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
