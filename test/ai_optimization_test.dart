
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lab_sense_app/core/ai_service.dart';
import 'package:lab_sense_app/core/cache_service.dart';
import 'package:lab_sense_app/core/vector_service.dart';

// Mocks
class MockCacheService extends Mock implements CacheService {}
class MockVectorService extends Mock implements VectorService {}

void main() {
  late AiService aiService;
  late MockCacheService mockCacheService;
  late MockVectorService mockVectorService;

  setUp(() {
    mockCacheService = MockCacheService();
    mockVectorService = MockVectorService();
    
    // Default cache miss
    when(() => mockCacheService.getAiCache(any())).thenReturn(null);
    when(() => mockCacheService.cacheAiResponse(any(), any())).thenAnswer((_) async {});
  });

  test('getHealthPredictions should call hook on cache miss and cache result', () async {
    // Arrange
    final history = [
      {'date': '2024-01-01', 'testResults': [{'name': 'A1c', 'value': 6.0, 'unit': '%', 'status': 'Normal'}]},
      {'date': '2024-02-01', 'testResults': [{'name': 'A1c', 'value': 6.2, 'unit': '%', 'status': 'Normal'}]},
    ];

    int apiCallCount = 0;

    // Use the hook
    Future<GenerateContentResponse> mockGenerator(Iterable<Content> content) async {
      apiCallCount++;
      return GenerateContentResponse(
        [Candidate(Content('model', [TextPart('[{"metric": "A1c", "predicted_value": "6.4"}]')]), null, null, null, null)], 
        null
      );
    }

    aiService = AiService(
      apiKey: 'dummy_key',
      vectorService: mockVectorService,
      cacheService: mockCacheService,
      mockTextGenerator: mockGenerator,
    );

    // Act
    final result = await aiService.getHealthPredictions(history);

    // Assert
    expect(result.isNotEmpty, true);
    expect(result.first['metric'], 'A1c');
    expect(apiCallCount, 1);
    
    // Verify Cache Set
    verify(() => mockCacheService.cacheAiResponse(any(), any())).called(1);
  });

  test('getHealthPredictions should return cached data and NOT call hook', () async {
    // Arrange
    final history = [
      {'date': '2024-01-01', 'testResults': [{'name': 'A1c', 'value': 6.0, 'unit': '%', 'status': 'Normal'}]},
      {'date': '2024-02-01', 'testResults': [{'name': 'A1c', 'value': 6.2, 'unit': '%', 'status': 'Normal'}]},
    ];

    final cachedData = [{'metric': 'A1c', 'predicted_value': '6.4', 'source': 'cache'}];
    
    // Simulate Cache Hit
    when(() => mockCacheService.getAiCache(any())).thenReturn(cachedData);

    int apiCallCount = 0;
    Future<GenerateContentResponse> mockGenerator(Iterable<Content> content) async {
      apiCallCount++;
      throw Exception('Should not be called');
    }

    aiService = AiService(
      apiKey: 'dummy_key',
      vectorService: mockVectorService,
      cacheService: mockCacheService,
      mockTextGenerator: mockGenerator,
    );

    // Act
    final result = await aiService.getHealthPredictions(history);

    // Assert
    expect(result.first['source'], 'cache');
    expect(apiCallCount, 0);
  });
}
