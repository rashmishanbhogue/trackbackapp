import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/entry.dart';

Future<String> classifyEntry(String text) async {
  final promptTemplate = PromptTemplate.fromTemplate(
    '''
Classify the following journal entry into a one-word category.
Some example categories: "Productive", "Distraction", "Learning", "Leisure", "Chore", "Social", etc.

Entry: {entry}
Category:
''',
  );

  final llm = ChatOpenAI(
    apiKey: dotenv.env['GROQ_API_KEY']!,
    baseUrl: 'https://api.groq.com/openai/v1',
  );

  final chain = promptTemplate.pipe(llm).pipe(const StringOutputParser());

  try {
    final result = await chain.invoke({'entry': text});
    return result.trim();
  } catch (e) {
    return 'Unknown';
  }
}
