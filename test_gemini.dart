import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  print('Testing API Key: $apiKey');

  if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('gen-lang-client')) {
    print('ERROR: The API Key looks invalid. It should start with "AIza".');
    exit(1);
  }

  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  final prompt = 'Tell me one word.';
  
  try {
    final response = await model.generateContent([Content.text(prompt)]);
    print('SUCCESS: AI responded: ${response.text}');
  } catch (e) {
    print('FAILURE: API call failed with error: $e');
    exit(1);
  }
}
