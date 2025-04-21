import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/entry.dart';

Future<String> classifyEntry(String text) async {
  final url = 'https://api.groq.com/openai/v1/chat/completions';
  final apiKey = dotenv.env['GROQ_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    return 'Uncategorized'; // fallback instead of error
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
        'content':
            'You are a strict classifier. Return only the label, no explanations, no extra text.'
      },
      {
        'role': 'user',
        'content': 'Classify this text into one label only:\n"$text"',
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
        final content = choices[0]['message']['content'];
        if (content != null) {
          return content.trim();
        }
      }
    }
  } catch (e) {
    print('Error during classification: $e');
  }

  return 'Uncategorized'; // safe fallback
}
