import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'vector_service.dart';
import 'app_config.dart';
import 'utils/rate_limiter.dart';

class LabTestAnalysis {
  final String description;
  final String status;
  final String resultContext;
  final String meaning;
  final List<String> factors;
  final List<String> questions;

  LabTestAnalysis({
    required this.description,
    required this.status,
    required this.resultContext,
    required this.meaning,
    required this.factors,
    required this.questions,
  });

  factory LabTestAnalysis.fromJson(Map<String, dynamic> json) {
    return LabTestAnalysis(
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      resultContext: json['resultContext'] ?? '',
      meaning: json['meaning'] ?? '',
      factors: List<String>.from(json['factors'] ?? []),
      questions: List<String>.from(json['questions'] ?? []),
    );
  }
}

class AiService {
  static final String _apiKey = AppConfig.geminiApiKey;
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );
  
  static final _rateLimiter = RateLimiter(maxRequests: 15, duration: const Duration(minutes: 1));

  static String _sanitizeInput(String input) {
    // Basic sanitization: remove potential script injections or extremely long inputs
    // In a medical context, we want to allow most text but limit length to prevent DoS via token exhaustion
    if (input.length > 2000) {
      return input.substring(0, 2000);
    }
    return input;
  }

  static Future<LabTestAnalysis> getSingleTestAnalysis({
    required String testName,
    required double value,
    required String unit,
    required String referenceRange,
  }) async {
    if (!_rateLimiter.canRequest()) {
       return LabTestAnalysis(
        description: 'Rate limit exceeded.',
        status: 'Error',
        resultContext: 'Please wait before requesting another analysis.',
        meaning: 'System overloaded.',
        factors: [],
        questions: [],
      );
    }
    
    testName = _sanitizeInput(testName);
    unit = _sanitizeInput(unit);
    referenceRange = _sanitizeInput(referenceRange);
    
    final prompt = '''
      Analyze the following lab test result and provide a structured JSON response.
      Test Name: $testName
      Result Value: $value
      Unit: $unit
      Reference Range: $referenceRange

      JSON Format:
      {
        "description": "Short explanation of what the test is",
        "status": "Low/Normal/High",
        "resultContext": "Sentence describing the result in context",
        "meaning": "What this result means for the user's health",
        "factors": ["Factor 1", "Factor 2"],
        "questions": ["Question 1", "Question 2"]
      }
      ONLY return the JSON.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      final data = jsonDecode(jsonStr);
      return LabTestAnalysis.fromJson(data);
    } catch (e) {
      // Fallback to mock for now if API fails
      // Try to extract limits from referenceRange if possible for basic status
      String status = 'Normal';
      try {
        final parts = referenceRange.split(' - ');
        if (parts.length == 2) {
          final min = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'), ''));
          final max = double.tryParse(parts[1].replaceAll(RegExp(r'[^0-9.]'), ''));
          if (min != null && value < min) status = 'Low';
          if (max != null && value > max) status = 'High';
        }
      } catch (_) {}

      return LabTestAnalysis(
        description: 'Failed to fetch AI analysis. This test measures $testName.',
        status: status,
        resultContext: 'Your $testName level is $value $unit.',
        meaning: 'Please consult your doctor for a detailed interpretation.',
        factors: ['Hydration', 'Diet', 'Recently taken medications'],
        questions: ['What does this result mean for me?'],
      );
    }
  }

  static Future<String> getBatchSummary(List<Map<String, dynamic>> tests) async {
    if (tests.isEmpty) return 'No lab results available for analysis.';

    final prompt = '''
      Analyze these lab results and provide a 2-3 sentence summary for a patient.
      Results: ${jsonEncode(tests)}
      
      Focus on highlighting if things are generally normal or if there are specific areas of concern.
      Be encouraging but professional.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'All values appear to be within the expected range based on the provided data.';
    } catch (e) {
      return 'Based on these lab results, most of your values fall within the normal range. Please discuss any outliers with your healthcare provider.';
    }
  }

  static Future<String> chat(String query) async {
    if (!_rateLimiter.canRequest()) {
      return 'Rate limit exceeded. Please wait a moment.';
    }
    
    query = _sanitizeInput(query);

    try {
      // 1. Get relevant context from Vector Store
      final vectorService = VectorService();
      final relevantChunks = await vectorService.searchSimilarChunks(query);
      
      final contextChunks = relevantChunks.map((chunk) {
        final content = chunk['content'] as String;
        final metadata = chunk['metadata'] as Map<String, dynamic>;
        return '''
Content: $content
Date: ${metadata['date']}
''';
      }).toList();

      // 2. Generate response using context
      return await getChatResponseWithContext(
        query: query,
        contextChunks: contextChunks,
      );
    } catch (e) {
      return 'I encountered an error analyzing your health data: $e';
    }
  }

  static Future<String> getChatResponseWithContext({
    required String query,
    required List<String> contextChunks,
  }) async {
    final contextText = contextChunks.isEmpty 
        ? "No specific lab results found relative to this query."
        : contextChunks.join('\n\n---\n\n');
        
    final prompt = '''
      You are LabSense AI, a medical assistant. Use the following lab result history (context) to answer the user's question.
      If the context doesn't contain the answer, say you don't have that specific data in your records but answer based on general medical knowledge while being clear about the distinction.
      
      Always be professional, encouraging, and remind the user this is educational, not medical advice.
      
      User Health Context:
      $contextText
      
      User Question: $query
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'I was unable to generate a response at this time.';
    } catch (e) {
      return 'Error generating response: $e';
    }
  }

  static Future<Map<String, dynamic>?> parseLabReport(Uint8List imageBytes, String mimeType) async {
    final prompt = '''
      You are a specialized medical lab report parser. Your task is to extract ALL test results from the provided image and return them in a valid JSON format.
      
      The JSON structure MUST be:
      {
        "lab_name": "String - Name of the laboratory or hospital",
        "date": "String - Date of the report in YYYY-MM-DD format (if possible)",
        "test_results": [
          {
            "test_name": "String - Full name of the test",
            "loinc": "String - LOINC code if mentioned",
            "result_value": "String - The numerical or categorical result",
            "unit": "String - The measurement unit",
            "reference_range": "String - The normal reference range",
            "status": "String - 'Normal', 'High', or 'Low' as indicated in the report"
          }
        ]
      }
      
      Important rules:
      1. ONLY return the JSON object. No other text.
      2. If a field is missing, leave it as an empty string or null.
      3. Be as accurate as possible.
    ''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      final data = jsonDecode(jsonStr);
      return data;
    } catch (e) {
      debugPrint('Error parsing lab report with AI: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getOptimizationTips(List<Map<String, dynamic>> abnormalTests) async {
    if (abnormalTests.isEmpty) return [];

    final prompt = '''
      You are a health optimization expert. Analyze these abnormal lab results and provide 3-4 personalized nutritional "Recipes" or "Optimization Tips".
      
      Results: ${jsonEncode(abnormalTests)}
      
      JSON Format:
      [
        {
          "title": "Short catchy title",
          "description": "Explanation of how this helps the specific deficiency",
          "ingredients": ["Ingredient 1", "Ingredient 2"],
          "instructions": "Simple action step or recipe instructions",
          "metric_targeted": "The lab test name this addresses",
          "benefit": "Core health benefit"
        }
      ]
      
      ONLY return the JSON array.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '[]';
      final List<dynamic> data = jsonDecode(jsonStr);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching optimization tips: $e');
      return [];
    }
  }
}
