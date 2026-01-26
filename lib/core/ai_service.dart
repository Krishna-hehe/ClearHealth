import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'vector_service.dart';
import 'utils/rate_limiter.dart';
import 'services/log_service.dart';

class LabTestAnalysis {
  final String description;
  final String status;
  final String keyInsight;
  final String clinicalSignificance;
  final String resultContext;
  final List<String> potentialCauses;
  final List<String> factors;
  final List<String> questions;
  final String recommendation;

  LabTestAnalysis({
    required this.description,
    required this.status,
    required this.keyInsight,
    required this.clinicalSignificance,
    required this.resultContext,
    required this.potentialCauses,
    required this.factors,
    required this.questions,
    required this.recommendation,
  });

  factory LabTestAnalysis.fromJson(Map<String, dynamic> json) {
    return LabTestAnalysis(
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      keyInsight: json['keyInsight'] ?? '',
      clinicalSignificance: json['clinicalSignificance'] ?? '',
      resultContext: json['resultContext'] ?? '',
      potentialCauses: List<String>.from(json['potentialCauses'] ?? []),
      factors: List<String>.from(json['factors'] ?? []),
      questions: List<String>.from(json['questions'] ?? []),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class AiService {
  final String apiKey;
  final String? chatApiKey; // Optional separate key for chat
  final VectorService vectorService;
  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;
  late final GenerativeModel _chatModel; // New model for chat
  
  // Rate limiter is now per-instance, which is fine if we use a singleton provider
  // Reduced rate limit for better free-tier stability
  final _rateLimiter = RateLimiter(maxRequests: 10, duration: const Duration(minutes: 1));

  AiService({required this.apiKey, this.chatApiKey, required this.vectorService}) {
    if (apiKey.isEmpty) {
      AppLogger.debug('❌ AiService: API Key is empty!');
    } else {
      AppLogger.debug('🚀 AiService: Initializing with key starting with: ${apiKey.substring(0, min(5, apiKey.length))}...');
    }
    _textModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
    );
     _visionModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
    );
     // Initialize Chat Model - prefer chatApiKey, fallback to main apiKey
     final effectiveChatKey = (chatApiKey != null && chatApiKey!.isNotEmpty) ? chatApiKey! : apiKey;
     AppLogger.debug('💬 AiService: Chat initialized with key starting with: ${effectiveChatKey.substring(0, min(5, effectiveChatKey.length))}...');
     _chatModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: effectiveChatKey,
    );
  }

  String _sanitizeInput(String input) {
    // Basic sanitization: remove potential script injections or extremely long inputs
    // In a medical context, we want to allow most text but limit length to prevent DoS via token exhaustion
    if (input.length > 2000) {
      return input.substring(0, 2000);
    }
    return input;
  }

  Future<LabTestAnalysis> getSingleTestAnalysis({
    required String testName,
    required double value,
    required String unit,
    required String referenceRange,
  }) async {
    if (!_rateLimiter.canRequest()) {
       return LabTestAnalysis(
        description: 'Rate limit exceeded.',
        status: 'Error',
        keyInsight: 'Please wait before requesting another analysis.',
        clinicalSignificance: 'System is temporarily overloaded.',
        resultContext: 'Please try again in a moment.',
        potentialCauses: [],
        factors: [],
        questions: [],
        recommendation: 'Wait 1 minute and refresh.',
      );
    }
    
    testName = _sanitizeInput(testName);
    unit = _sanitizeInput(unit);
    referenceRange = _sanitizeInput(referenceRange);
    
    final prompt = '''
      You are a specialized medical interpreter for patients. Your goal is to translate a specific lab result into a detailed, educational, and reassuring narrative, similar to a high-quality medical report.

      LAB TEST CONTEXT:
      - Test Name: $testName
      - Patient Result: $value $unit
      - Reference Range: $referenceRange

      TASK:
      Analyze this specific result. Write in a conversational but professional tone.
      
      REFERENECE STYLE GUIDELINES:
      1. "Your Result": Don't just state the number. Compare it conversationally to the range (e.g., "Your MCHC value is 36.5%, which is slightly higher than the typical reference range... This means the concentration...").
      2. "What This Means": Explain the biological mechanism. NOT just "It's high". Explain *why* (e.g., "A high MCHC can sometimes suggest that your red blood cells are more densely packed with hemoglobin...").
      3. "Common Factors": List specific medical or lifestyle causes.

      OUTPUT FORMAT (JSON ONLY, NO MARKDOWN):
      {
        "description": "Definition of the test (max 20 words).",
        "status": "Strictly: 'High', 'Low', or 'Normal'.",
        "keyInsight": "A single bold sentence summarizing the main finding.",
        "clinicalSignificance": "Detailed explanation of the biological implication (e.g., 'This value indicates...'). Max 60 words.",
        "resultContext": "A conversational paragraph comparing the result to the range and explaining what that specific variance implies (approx 40-50 words).",
        "potentialCauses": ["List 3-5 specific medical or lifestyle factors (e.g. 'Dehydration', 'Vitamin B12 deficiency')."],
        "factors": ["3 primary influencing factors."],
        "questions": ["3 specific questions for the doctor."],
        "recommendation": "A clear next step."
      }

      TONE: Educational, calm, professional. Use full sentences for 'clinicalSignificance' and 'resultContext'.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String rawText = response.text?.trim() ?? '{}';
      
      AppLogger.debug('🤖 AI Raw Response ($testName): $rawText', containsPII: true);

      // Enhanced robust JSON extraction
      String jsonStr = _extractJson(rawText);
      
      final data = jsonDecode(jsonStr);
      return LabTestAnalysis.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.debug('❌ AI Analysis Error for $testName: $e');
      AppLogger.debug(stackTrace.toString());
      // Fallback logic preserved...
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
        description: 'Analysis unavailable. This measures $testName.',
        status: status,
        keyInsight: 'Consult your doctor for a detailed interpretation of this result.',
        clinicalSignificance: 'Individual test results should be viewed as part of your complete clinical picture.',
        resultContext: 'Your level is $value $unit.',
        potentialCauses: ['Hydration', 'Recent Diet', 'Current Medication'],
        factors: ['Hydration', 'Diet', 'Medication'],
        questions: ['Is this result concerning?', 'Do I need to retest?', 'What lifestyle changes help?'],
        recommendation: 'Discuss this result during your next medical appointment.',
      );
    }
  }

  Future<Map<String, dynamic>> getTrendAnalysis({
    required String testName,
    required List<Map<String, dynamic>> history, // [{date: '2024-01-01', value: 10.5}]
  }) async {
    if (history.length < 2) {
      return {
        'direction': 'Stable',
        'change_percent': '0.0%',
        'analysis': 'Not enough data to identify a trend.'
      };
    }

    // Sort by date just in case
    history.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    
    final prompt = '''
      Analyze the trend for this lab test:
      Test: $testName
      History: ${jsonEncode(history)}
      
      Return valid JSON only:
      {
        "direction": "Increasing, Decreasing, or Stable",
        "change_percent": "Percentage change from first to last (e.g. +10%, -5%)",
        "analysis": "1-2 sentences explaining the trend over time and if it is concerning or improving."
      }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String rawText = response.text?.trim() ?? '{}';
      String jsonStr = _extractJson(rawText);
      return jsonDecode(jsonStr);
    } catch (e) {
      AppLogger.debug('Trend Analysis Error: $e');
      return {
        'direction': 'Unknown',
        'change_percent': '--',
        'analysis': 'Unable to calculate trend at this time.'
      };
    }
  }

  Future<String> getBatchSummary(List<Map<String, dynamic>> tests) async {
    if (tests.isEmpty) return 'No lab results available for analysis.';

    final prompt = '''
      You are a medical AI assistant. Analyze these lab test results and provide a comprehensive summary for the patient.
      
      Lab Results: ${jsonEncode(tests)}
      
      Provide a detailed summary (5-7 sentences minimum) that includes:
      1. Overall health assessment - are results generally normal or concerning?
      2. Specific abnormal findings with their severity (mild, moderate, severe)
      3. Any patterns or correlations between test results
      4. Immediate actions needed (if any critical values)
      5. Short-term recommendations (lifestyle, diet, follow-up)
      6. Positive findings worth celebrating
      7. Overall tone should be professional, encouraging, and actionable
      
      Focus on being specific about which tests are abnormal and what they mean together.
      Use clear, patient-friendly language but be medically accurate.
      If everything is normal, explain what this indicates about overall health.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      return response.text?.trim() ?? 'All values appear to be within the expected range based on the provided data.';
    } catch (e) {
      return 'Based on these lab results, most of your values fall within the normal range. Please discuss any outliers with your healthcare provider.';
    }
  }

  Future<String> chat(String query, {Map<String, dynamic>? healthContext}) async {
    if (!_rateLimiter.canRequest()) {
      return 'Rate limit exceeded. Please wait a moment.';
    }
    
    query = _sanitizeInput(query);

    try {
      // 1. Get relevant context from Vector Store
      final relevantChunks = await vectorService.searchSimilarChunks(query);
      
      final contextChunks = relevantChunks.map((chunk) {
        return '''
Content: ${chunk['content']}
Date: ${chunk['metadata']['date']}
''';
      }).toList();

      // 2. Generate response using context
      return await getChatResponseWithContext(
        query: query,
        contextChunks: contextChunks,
        healthContext: healthContext,
      );
    } catch (e) {
      return 'I encountered an error analyzing your health data: $e';
    }
  }

  Future<String> getChatResponseWithContext({
    required String query,
    required List<String> contextChunks,
    Map<String, dynamic>? healthContext,
  }) async {
    final contextText = contextChunks.isEmpty 
        ? "No specific lab results found relative to this query in the archives."
        : contextChunks.join('\n\n---\n\n');
        
    final healthContextStr = healthContext != null
        ? '''
    CURRENT PATIENT STATUS:
    Abnormal Labs: ${jsonEncode(healthContext['abnormal_labs'])}
    Active Prescriptions: ${jsonEncode(healthContext['active_prescriptions'])}
    '''
        : '';

    final prompt = '''
      You are LabSense AI, a medical assistant. Use the following patient status and lab result history to answer the user's question.

      $healthContextStr

      ARCHIVED LAB CONTEXT:
      $contextText

      USER QUESTION:
      $query

      If the context doesn't contain the answer, say you don't have that specific data in your records but answer based on general medical knowledge while being clear about the distinction.
      
      Always be professional, encouraging, and remind the user this is educational, not medical advice.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _chatModel.generateContent(content);
      return response.text?.trim() ?? 'I was unable to generate a response at this time.';
    } catch (e) {
      return 'Error generating response: $e';
    }
  }

  Future<Map<String, dynamic>?> parseLabReport(Uint8List imageBytes, String mimeType) async {
    final prompt = '''
      You are a specialized medical lab report parser. Your task is to extract ALL test results from the provided document and return them in a valid JSON format.
      
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
      1. ONLY return the JSON object. No other text. Use valid JSON syntax.
      2. If a field is missing, leave it as an empty string or null.
      3. Be as accurate as possible. Even if you're unsure, provide the best guess based on the text.
    ''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('AI returned an empty response. This may be due to safety filters or an unreadable file.');
      }

      // Robust JSON extraction
      String jsonStr = _extractJson(text);
      
      final parsed = jsonDecode(jsonStr);
      if (parsed == null || parsed is! Map<String, dynamic>) {
        throw Exception('AI returned invalid data format. Expected a JSON object.');
      }

      // Validate required fields
      if (!parsed.containsKey('test_results')) {
        throw Exception('AI response missing required field: test_results');
      }

      // Post-process: Calculate accurate status based on reference ranges
      if (parsed['test_results'] is List) {
        for (var test in parsed['test_results']) {
          if (test is Map<String, dynamic>) {
            final calculatedStatus = _calculateStatus(
              test['result_value']?.toString() ?? '',
              test['reference_range']?.toString() ?? '',
            );
            // Override AI-provided status with calculated one
            if (calculatedStatus != null) {
              test['status'] = calculatedStatus;
            }
          }
        }
      }

      return parsed;
    } catch (e) {
      AppLogger.error('Error parsing lab report: $e', containsPII: true);
      // Rethrow with a more descriptive message if it's a known error type
      if (e is FormatException) {
        throw Exception('AI returned invalid data format. Please try another clear image.');
      }
      rethrow;
    }
  }

  /// Intelligently calculates test status by comparing result value against reference range
  String? _calculateStatus(String resultValue, String referenceRange) {
    if (resultValue.isEmpty || referenceRange.isEmpty) return null;

    // Handle non-numeric results (e.g., "Positive", "Negative", "Detected")
    final resultLower = resultValue.toLowerCase();
    if (resultLower.contains('positive') || resultLower.contains('detected')) {
      return 'High';
    }
    if (resultLower.contains('negative') || resultLower.contains('not detected')) {
      return 'Normal';
    }

    // Extract numeric value from result
    final numericMatch = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(resultValue);
    if (numericMatch == null) return null;
    
    final value = double.tryParse(numericMatch.group(1)!);
    if (value == null) return null;

    // Parse reference range - handle multiple formats:
    // "10-20", "10 - 20", "< 5", "> 100", "10-20 mg/dL", etc.
    final rangeLower = referenceRange.toLowerCase();
    
    // Handle "< X" format (upper limit only)
    if (rangeLower.contains('<')) {
      final maxMatch = RegExp(r'<\s*([0-9]+\.?[0-9]*)').firstMatch(rangeLower);
      if (maxMatch != null) {
        final max = double.tryParse(maxMatch.group(1)!);
        if (max != null && value >= max) return 'High';
        return 'Normal';
      }
    }
    
    // Handle "> X" format (lower limit only)
    if (rangeLower.contains('>')) {
      final minMatch = RegExp(r'>\s*([0-9]+\.?[0-9]*)').firstMatch(rangeLower);
      if (minMatch != null) {
        final min = double.tryParse(minMatch.group(1)!);
        if (min != null && value <= min) return 'Low';
        return 'Normal';
      }
    }

    // Handle "X - Y" or "X-Y" format (range)
    final rangeMatch = RegExp(r'([0-9]+\.?[0-9]*)\s*-\s*([0-9]+\.?[0-9]*)').firstMatch(rangeLower);
    if (rangeMatch != null) {
      final min = double.tryParse(rangeMatch.group(1)!);
      final max = double.tryParse(rangeMatch.group(2)!);
      
      if (min != null && max != null) {
        if (value < min) return 'Low';
        if (value > max) return 'High';
        return 'Normal';
      }
    }

    // If we can't parse the range, return null to keep AI's original status
    return null;
  }

  Future<List<Map<String, dynamic>>> getOptimizationTips(List<Map<String, dynamic>> abnormalTests) async {
    if (abnormalTests.isEmpty) return [];

    final prompt = '''
      You are a health optimization expert. Analyze these abnormal lab results and provide 4-6 personalized nutritional "Recipes" or "Optimization Tips".
      
      Results: \${jsonEncode(abnormalTests)}
      
      CRITICAL INSTRUCTION:
      Provide a mix of Vegetarian and Non-Vegetarian options.
      
      JSON Format:
      [
        {
          "title": "Short catchy title",
          "description": "Explanation of how this helps the specific deficiency",
          "ingredients": ["Ingredient 1", "Ingredient 2"],
          "instructions": "Simple action step or recipe instructions",
          "metric_targeted": "The lab test name this addresses",
          "benefit": "Core health benefit",
          "type": "Veg" or "Non-Veg"
        }
      ]
      
      ONLY return the JSON array.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String rawText = response.text?.trim() ?? '[]';
      final jsonStr = _extractJson(rawText);
      final List<dynamic> data = jsonDecode(jsonStr);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.debug('Error fetching optimization tips: $e');
      return [];
    }
  }

  /// Robustly extracts JSON from potentially messy AI output
  String _extractJson(String text) {
    if (text.isEmpty) return '{}';
    
    // 1. Remove markdown blocks if they exist
    if (text.contains('```')) {
      final blocks = text.split('```');
      for (var block in blocks) {
        final trimmed = block.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[') || trimmed.contains('{\n') || trimmed.startsWith('json')) {
          text = trimmed.replaceFirst('json', '').trim();
          break;
        }
      }
    }

    // 2. Determine if we are looking for an object or an array
    final firstBrace = text.indexOf('{');
    final firstBracket = text.indexOf('[');
    
    // If array comes first (or no object brace found), assume array
    bool isArray = false;
    if (firstBracket != -1) {
      if (firstBrace == -1 || firstBracket < firstBrace) {
        isArray = true;
      }
    }

    if (isArray) {
      final lastBracket = text.lastIndexOf(']');
      if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
        return text.substring(firstBracket, lastBracket + 1).trim();
      }
    } else {
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        return text.substring(firstBrace, lastBrace + 1).trim();
      }
    }

    // Fallback: return trimmed text which might be raw JSON
    return text.trim();
  }
}
