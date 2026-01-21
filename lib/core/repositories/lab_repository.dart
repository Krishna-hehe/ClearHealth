import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import '../models.dart';
import '../cache_service.dart';

class LabRepository {
  final SupabaseService _supabaseService;
  final CacheService _cacheService;

  LabRepository(this._supabaseService, this._cacheService);

  Future<List<LabReport>> getLabResults({int limit = 10}) async {
    try {
      final data = await _supabaseService.getLabResults(limit: limit);
      await _cacheService.cacheLabResults(data);
      return data.map((json) => LabReport.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Supabase fetch failed, falling back to cache: $e');
      final cachedData = _cacheService.getCachedLabResults();
      return cachedData.map((json) => LabReport.fromJson(json)).toList();
    }
  }

  Future<void> createLabResult(Map<String, dynamic> data) async {
    await _supabaseService.createLabResult(data);
  }

  Future<void> deleteLabResult(String id) async {
    await _supabaseService.deleteLabResult(id);
  }

  Future<List<Map<String, dynamic>>> getTrendData(String testName) async {
    try {
      return await _supabaseService.getTrendData(testName);
    } catch (e) {
      debugPrint('Error fetching trend data: $e');
      return [];
    }
  }

  Future<List<String>> getDistinctTests() async {
    return await _supabaseService.getDistinctTests();
  }
}
