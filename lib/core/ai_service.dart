import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'vector_service.dart';
import 'utils/rate_limiter.dart';
import 'services/log_service.dart';
import 'cache_service.dart';

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
  final CacheService cacheService;
  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;
  late final GenerativeModel _chatModel;

  final _rateLimiter = RateLimiter(
    maxRequests: 10,
    duration: const Duration(minutes: 1),
  );

  // Test hook
  final Future<GenerateContentResponse> Function(Iterable<Content> content)?
  mockTextGenerator;

  AiService({
    required this.apiKey,
    this.chatApiKey,
    required this.vectorService,
    required this.cacheService,
    GenerativeModel? textModel,
    GenerativeModel? visionModel,
    GenerativeModel? chatModel,
    this.mockTextGenerator,
  }) {
    if (apiKey.isEmpty) {
      AppLogger.debug('❌ AiService: API Key is empty!');
    } else {
      AppLogger.debug(
        '🚀 AiService: Initializing with key starting with: ${apiKey.substring(0, min(5, apiKey.length))}...',
      );
    }
    _textModel =
        textModel ??
        GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
    _visionModel =
        visionModel ??
        GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
    // Initialize Chat Model - prefer chatApiKey, fallback to main apiKey
    final effectiveChatKey = (chatApiKey != null && chatApiKey!.isNotEmpty)
        ? chatApiKey!
        : apiKey;
    AppLogger.debug(
      '💬 AiService: Chat initialized with key starting with: ${effectiveChatKey.substring(0, min(5, effectiveChatKey.length))}...',
    );
    _chatModel =
        chatModel ??
        GenerativeModel(model: 'gemini-flash-latest', apiKey: effectiveChatKey);
  }

  String _sanitizeInput(String input) {
    if (input.length > 2000) {
      return input.substring(0, 2000);
    }
    return input;
  }

  /// Generates a unique cache key based on operation name and input data hash
  String _generateCacheKey(String operation, dynamic data) {
    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    final hash = sha256.convert(bytes).toString().substring(0, 16);
    return 'ai_${operation}_$hash';
  }

  /// Minifies lab history to reduce token usage
  List<Map<String, dynamic>> _minifyHistory(
    List<Map<String, dynamic>> history,
  ) {
    return history.map((report) {
      List<Map<String, dynamic>> meaningfulTests = [];
      if (report['testResults'] != null) {
        for (var test in report['testResults']) {
          // We only keep essential fields
          meaningfulTests.add({
            'n': test['name'] ?? test['test_name'],
            'v': test['result'] ?? test['value'],
            'u': test['unit'],
            's': test['status'], // 'High', 'Low', 'Normal'
          });
        }
      }
      return {'d': report['date'], 't': meaningfulTests};
    }).toList();
  }

  Future<LabTestAnalysis> getSingleTestAnalysis({
    required String testName,
    required double value,
    required String unit,
    required String referenceRange,
  }) async {
    final cacheKey = _generateCacheKey('single_analysis', {
      'n': testName,
      'v': value,
      'u': unit,
    });
    final cached = cacheService.getAiCache(cacheKey);
    if (cached != null) {
      return LabTestAnalysis.fromJson(Map<String, dynamic>.from(cached));
    }

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

    final prompt =
        '''
      You are a specialized medical interpreter for patients. Your goal is to translate a specific lab result into a detailed, educational, and reassuring narrative.
      
      LAB TEST CONTEXT:
      - Test Name: $testName
      - Patient Result: $value $unit
      - Reference Range: $referenceRange
      
      OUTPUT FORMAT (JSON ONLY):
      {
        "description": "Definition (max 20 words).",
        "status": "Strictly: 'High', 'Low', or 'Normal'.",
        "keyInsight": "Bold summary sentence.",
        "clinicalSignificance": "Explanation (max 60 words).",
        "resultContext": "Conversational comparison to range.",
        "potentialCauses": ["List 3-5 factors."],
        "factors": ["3 primary factors."],
        "questions": ["3 specific doctor questions."],
        "recommendation": "Next step."
      }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String rawText = response.text?.trim() ?? '{}';

      AppLogger.debug(
        '🤖 AI Raw Response ($testName): $rawText',
        containsPII: true,
      );

      String jsonStr = _extractJson(rawText);
      final data = jsonDecode(jsonStr);

      // Cache the result
      cacheService.cacheAiResponse(cacheKey, data);

      return LabTestAnalysis.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.debug('❌ AI Analysis Error for $testName: $e');
      AppLogger.debug(stackTrace.toString());

      return LabTestAnalysis(
        description: 'Analysis unavailable. This measures $testName.',
        status: 'Normal', // Default
        keyInsight: 'Consult your doctor.',
        clinicalSignificance:
            'Individual test results should be viewed as part of your complete clinical picture.',
        resultContext: 'Your level is $value $unit.',
        potentialCauses: [],
        factors: [],
        questions: [],
        recommendation: 'Discuss with your doctor.',
      );
    }
  }

  Future<Map<String, dynamic>> getTrendAnalysis({
    required String testName,
    required List<Map<String, dynamic>> history,
  }) async {
    if (history.length < 2) {
      return {
        'direction': 'Stable',
        'change_percent': '0.0%',
        'analysis': 'Not enough data to identify a trend.',
      };
    }

    history.sort(
      (a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
    );

    // Only use dates and values for cache/prompt to save tokens
    final minifiedHistory = history
        .map((h) => {'d': h['date'], 'v': h['value']})
        .toList();
    final cacheKey = _generateCacheKey('trend', {
      't': testName,
      'h': minifiedHistory,
    });

    final cached = cacheService.getAiCache(cacheKey);
    if (cached != null) return Map<String, dynamic>.from(cached);

    final prompt =
        '''
      Analyze the trend for: $testName
      Data: ${jsonEncode(minifiedHistory)}
      
      JSON ONLY:
      {
        "direction": "Increasing, Decreasing, or Stable",
        "change_percent": "e.g. +10%",
        "analysis": "1 sentence explanation."
      }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String rawText = response.text?.trim() ?? '{}';
      String jsonStr = _extractJson(rawText);
      final data = jsonDecode(jsonStr);

      cacheService.cacheAiResponse(cacheKey, data);
      return data;
    } catch (e) {
      AppLogger.debug('Trend Analysis Error: $e');
      return {
        'direction': 'Unknown',
        'change_percent': '--',
        'analysis': 'Unable to calculate trend at this time.',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getOptimizationTips(
    List<Map<String, dynamic>> abnormalTests,
  ) async {
    if (abnormalTests.isEmpty) return [];

    // Minimize input
    final minifiedTests = abnormalTests
        .map(
          (t) => {
            'n': t['name'] ?? t['test_name'],
            'v': t['result'] ?? t['value'],
            's': t['status'],
          },
        )
        .toList();

    final cacheKey = _generateCacheKey('opt_tips', minifiedTests);

    final cached = cacheService.getAiCache(cacheKey);
    if (cached != null) {
      return (cached as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final prompt = '''
      You are a health optimization expert. Provide 4-6 nutritional tips for these abnormal results.
      
      Results: \${jsonEncode(minifiedTests)}
      
      Include Veg and Non-Veg.
      
      JSON Format:
      [
        {
          "title": "Title",
          "description": "Why it helps",
          "ingredients": ["Item 1"],
          "instructions": "Action",
          "metric_targeted": "Test Name",
          "benefit": "Benefit",
          "type": "Veg/Non-Veg"
        }
      ]
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String rawText = response.text?.trim() ?? '[]';
      final jsonStr = _extractJson(rawText);
      final List<dynamic> data = jsonDecode(jsonStr);

      cacheService.cacheAiResponse(cacheKey, data);

      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      AppLogger.debug('Error fetching optimization tips: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHealthPredictions(
    List<Map<String, dynamic>> fullHistory,
  ) async {
    if (fullHistory.length < 2) return [];

    final recentHistory = fullHistory.take(5).toList();
    final minifiedHistory = _minifyHistory(recentHistory);

    final cacheKey = _generateCacheKey('predictions', minifiedHistory);
    final cached = cacheService.getAiCache(cacheKey);
    if (cached != null) {
      return (cached as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final prompt = '''
      Predictive Analyst. Forecast trends (3mo) based on this history (d=date, n=test, v=val, s=status).
      
      Data: \${jsonEncode(minifiedHistory)}
      
      JSON Only:
      [
        {
          "metric": "HbA1c",
          "current_value": "6.1",
          "predicted_value": "6.3",
          "trend_direction": "Increasing",
          "risk_level": "Medium",
          "insight": "Insight...",
          "recommendation": "Advice..."
        }
      ]
    ''';

    try {
      final content = [Content.text(prompt)];

      final response = mockTextGenerator != null
          ? await mockTextGenerator!(content)
          : await _textModel.generateContent(content);

      String rawText = response.text?.trim() ?? '[]';
      final jsonStr = _extractJson(rawText);
      final List<dynamic> data = jsonDecode(jsonStr);

      cacheService.cacheAiResponse(cacheKey, data);

      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      AppLogger.error('Error fetching health predictions: $e');
      return [];
    }
  }

  Future<String> getBatchSummary(List<Map<String, dynamic>> tests) async {
    if (tests.isEmpty) return 'No lab results available.';

    final minifiedTests = _minifyHistory(tests);
    final cacheKey = _generateCacheKey('batch_summary', minifiedTests);

    final cached = cacheService.getAiCache(cacheKey);
    if (cached != null) return cached.toString();

    final prompt = '''
      Medical AI. Summarize these lab results (JSON).
      
      Data: \${jsonEncode(minifiedTests)}
      
      Summary (5-7 sentences):
      1. Overall assessment.
      2. Abnormal findings.
      3. Recommendations.
      
      Patient-friendly language.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      final text = response.text?.trim() ?? 'Analysis incomplete.';

      cacheService.cacheAiResponse(cacheKey, text);
      return text;
    } catch (e) {
      return 'Unable to generate summary at this time.';
    }
  }

  Future<String> chat(
    String query, {
    Map<String, dynamic>? healthContext,
  }) async {
    if (!_rateLimiter.canRequest())
      return 'Rate limit exceeded. Please wait a moment.';

    query = _sanitizeInput(query);

    try {
      final relevantChunks = await vectorService.searchSimilarChunks(query);

      final contextChunks = relevantChunks.map((chunk) {
        return 'Content: ${chunk['content']}\nDate: ${chunk['metadata']['date']}';
      }).toList();

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
    // Chat is dynamic, harder to cache effectively without strict keys, skipping for now

    final contextText = contextChunks.isEmpty
        ? "No specific records found."
        : contextChunks.join('\\n\\n---\\n\\n');

    String healthContextStr = '';
    if (healthContext != null) {
      // Minify health context too
      final abnormal = (healthContext['abnormal_labs'] as List?)
          ?.map((t) => {'n': t['name'], 'v': t['result'], 's': t['status']})
          .toList();
      healthContextStr =
          "Context: Abnormal=\${jsonEncode(abnormal)}, Meds=\${jsonEncode(healthContext['active_prescriptions'])}";
    }

    final prompt =
        '''
      LabSense AI Assistant.
      
      $healthContextStr
      
      Files:
      $contextText
      
      User: $query
      
      Answer professionally.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _chatModel.generateContent(content);
      return response.text?.trim() ?? 'I was unable to generate a response.';
    } catch (e) {
      return 'Error generating response: \$e';
    }
  }

  Future<Map<String, dynamic>?> parseLabReport(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    // Vision cannot be cached easily by hash of bytes (too big), and usually one-off operation
    final prompt = '''
      Parse this lab report into JSON:
      {
        "lab_name": "String",
        "date": "YYYY-MM-DD",
        "test_results": [
          {
            "test_name": "String",
            "result_value": "String",
            "unit": "String",
            "reference_range": "String",
            "status": "High/Low/Normal"
          }
        ]
      }
    ''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]),
      ];

      final response = await _visionModel.generateContent(content);
      final text = response.text;
      if (text == null || text.isEmpty) throw Exception('Empty response');

      String jsonStr = _extractJson(text);
      final parsed = jsonDecode(jsonStr);

      if (parsed is! Map<String, dynamic> ||
          !parsed.containsKey('test_results')) {
        throw Exception('Invalid JSON format');
      }

      // Helper function _calculateStatus was used before, need to re-add it or keep simple
      if (parsed['test_results'] is List) {
        for (var test in parsed['test_results']) {
          if (test is Map<String, dynamic>) {
            test['status'] =
                _calculateStatus(
                  test['result_value']?.toString() ?? '',
                  test['reference_range']?.toString() ?? '',
                ) ??
                test['status'];
          }
        }
      }

      return parsed;
    } catch (e) {
      AppLogger.error('Error parsing lab report: $e');
      rethrow;
    }
  }

  String? _calculateStatus(String resultValue, String referenceRange) {
    if (resultValue.isEmpty || referenceRange.isEmpty) return null;
    final resultLower = resultValue.toLowerCase();
    if (resultLower.contains('positive') || resultLower.contains('detected'))
      return 'High';
    if (resultLower.contains('negative') ||
        resultLower.contains('not detected'))
      return 'Normal';

    final numericMatch = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(resultValue);
    if (numericMatch == null) return null;
    final value = double.tryParse(numericMatch.group(1)!);
    if (value == null) return null;

    final rangeLower = referenceRange.toLowerCase();

    if (rangeLower.contains('<')) {
      final maxMatch = RegExp(r'<\s*([0-9]+\.?[0-9]*)').firstMatch(rangeLower);
      if (maxMatch != null) {
        final max = double.tryParse(maxMatch.group(1)!);
        if (max != null) return value >= max ? 'High' : 'Normal';
      }
    }

    if (rangeLower.contains('>')) {
      final minMatch = RegExp(r'>\s*([0-9]+\.?[0-9]*)').firstMatch(rangeLower);
      if (minMatch != null) {
        final min = double.tryParse(minMatch.group(1)!);
        if (min != null) return value <= min ? 'Low' : 'Normal';
      }
    }

    final rangeMatch = RegExp(
      r'([0-9]+\.?[0-9]*)\s*-\s*([0-9]+\.?[0-9]*)',
    ).firstMatch(rangeLower);
    if (rangeMatch != null) {
      final min = double.tryParse(rangeMatch.group(1)!);
      final max = double.tryParse(rangeMatch.group(2)!);
      if (min != null && max != null) {
        if (value < min) return 'Low';
        if (value > max) return 'High';
        return 'Normal';
      }
    }

    return null;
  }

  String _extractJson(String text) {
    if (text.isEmpty) return '{}';
    if (text.contains('```')) {
      final blocks = text.split('```');
      for (var block in blocks) {
        final trimmed = block.trim();
        if (trimmed.startsWith('{') ||
            trimmed.startsWith('[') ||
            trimmed.contains('{\n') ||
            trimmed.startsWith('json')) {
          text = trimmed.replaceFirst('json', '').trim();
          break;
        }
      }
    }
    final firstBrace = text.indexOf('{');
    final firstBracket = text.indexOf('[');
    bool isArray = false;
    if (firstBracket != -1) {
      if (firstBrace == -1 || firstBracket < firstBrace) isArray = true;
    }

    if (isArray) {
      final lastBracket = text.lastIndexOf(']');
      if (firstBracket != -1 &&
          lastBracket != -1 &&
          lastBracket > firstBracket) {
        return text.substring(firstBracket, lastBracket + 1).trim();
      }
    } else {
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        return text.substring(firstBrace, lastBrace + 1).trim();
      }
    }
    return text.trim();
  }
}
