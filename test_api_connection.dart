import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyB-g1FNoMqM4U0ucRAvw2wyjW9YWNnJsJ0';
  
  print('Testing API Key: ${apiKey.substring(0, 5)}...');
  
  final model = GenerativeModel(
    model: 'gemini-flash-latest',
    apiKey: apiKey,
  );

  try {
    print('Sending test request...');
    final response = await model.generateContent([
      Content.text('Explain RDW blood test in one sentence.')
    ]);
    
    print('✅ Success!');
    print('Response: ${response.text}');
  } catch (e) {
    print('❌ API Error: $e');
  }
}
