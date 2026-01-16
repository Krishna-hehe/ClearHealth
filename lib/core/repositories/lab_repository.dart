import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class LabRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<LabReport>> getLabResults() async {
    try {
      final response = await _client
          .from('lab_results')
          .select()
          .order('date', ascending: false);

      return (response as List).map((json) => LabReport.fromJson(json)).toList();
    } catch (e) {
      // In a real app, you might rethrow or return a Result type
      // print('Error fetching lab results: $e'); // Avoid print in production code
      return [];
    }
  }

  // Add other methods (upload, delete) here
}
