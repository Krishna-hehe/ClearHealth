import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import '../models.dart';
import '../cache_service.dart';
import '../storage_service.dart';

class LabRepository {
  final SupabaseService _supabaseService;
  final CacheService _cacheService;
  final StorageService? _storageService;

  LabRepository(this._supabaseService, this._cacheService, [this._storageService]);

  Future<List<LabReport>> getLabResults({int limit = 10, int offset = 0}) async {
    try {
      final data = await _supabaseService.getLabResults(limit: limit, offset: offset);
      if (offset == 0) {
        await _cacheService.cacheLabResults(data);
      }
      return data.map((json) => LabReport.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Supabase fetch failed, falling back to cache: $e');
      if (offset == 0) {
        final cachedData = _cacheService.getCachedLabResults();
        return cachedData.map((json) => LabReport.fromJson(json)).toList();
      }
      return []; // Pagination fallback
    }
  }

  Future<void> createLabResult(Map<String, dynamic> data) async {
    await _supabaseService.createLabResult(data);
  }

  Future<void> deleteLabResult(String id, {String? storagePath}) async {
    // 1. Delete from DB first (if RLS fails, we shouldn't delete storage)
    await _supabaseService.deleteLabResult(id);

    // 2. Delete from Storage if path provided
    if (storagePath != null) {
      await _storageService?.deleteLabReportFile(storagePath);
    }
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
