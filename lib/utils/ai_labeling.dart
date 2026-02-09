// ai_labeling.dart, access groq-llama to receive the category input

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

Future<String> classifyEntry(String text) async {
  const url = 'https://api.groq.com/openai/v1/chat/completions';
  final apiKey = dotenv.env['GROQ_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    return 'Uncategorised'; // fallback instead of error
  }

  final headers = {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  final body = jsonEncode({
    'model': 'llama3-8b-8192',
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
        'content': 'Classify this text:\n"$text"',
      }
    ],
    'temperature': 0.0,
  });

  try {
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'];
      if (choices != null && choices.isNotEmpty) {
        final content = choices[0]['message']['content']?.trim();
        if (content != null && standardCategories.contains(content)) {
          return content;
        }
      }
    }
  } catch (e) {
    debugPrint('Error during classification: $e');
  }

  return 'Uncategorised'; // safe fallback
}
