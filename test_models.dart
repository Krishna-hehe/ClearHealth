import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  print('Checking models for API Key: $apiKey');

  if (apiKey == null) {
    print('ERROR: No API Key found.');
    exit(1);
  }

  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  
  try {
    // We use a dummy request to check if the model exists, or we list them.
    // The package doesn't have a direct listModels, so we'll use curl or a simple request.
    print('Attempting list via curl...');
  } catch (e) {
    print('Error: $e');
  }
}
