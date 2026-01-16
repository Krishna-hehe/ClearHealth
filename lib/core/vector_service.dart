import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class VectorService {
  final GenerativeModel _model;
  final SupabaseClient _client;

  VectorService(this._client, {required String apiKey}) 
      : _model = GenerativeModel(
          model: 'text-embedding-004', 
          apiKey: apiKey,
        );

  /// Generates a vector embedding for the given text using Gemini.
  Future<List<double>> generateEmbedding(String text) async {
    final content = Content.text(text);
    final response = await _model.embedContent(content);
    return response.embedding.values;
  }

  /// Ingests a [TestResult] into the vector database.
  Future<void> ingestLabResult(TestResult result, String date) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final content = '''
Test: ${result.name}
Result: ${result.result} ${result.unit}
Reference Range: ${result.reference}
Status: ${result.status}
Date: $date
''';

    final embedding = await generateEmbedding(content);

    await _client.from('test_embeddings').insert({
      'user_id': user.id,
      'test_name': result.name,
      'content': content,
      'metadata': {
        'date': date,
        'status': result.status,
        'loinc': result.loinc,
      },
      'embedding': embedding,
    });
  }

  /// Searches for similar lab result chunks based on a query.
  Future<List<Map<String, dynamic>>> searchSimilarChunks(String query, {int limit = 5}) async {
    final embedding = await generateEmbedding(query);

    final response = await _client.rpc('match_test_embeddings', params: {
      'query_embedding': embedding,
      'match_threshold': 0.5,
      'match_count': limit,
    });

    return List<Map<String, dynamic>>.from(response);
  }
}
