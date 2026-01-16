import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import '../cache_service.dart';

class UserRepository {
  final SupabaseService _supabaseService;
  final CacheService _cacheService;

  UserRepository(this._supabaseService, this._cacheService);

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final data = await _supabaseService.getProfile();
      if (data != null) {
        await _cacheService.cacheProfile(data);
      }
      return data;
    } catch (e) {
      debugPrint('Supabase fetch failed, falling back to cache: $e');
      return _cacheService.getCachedProfile();
    }
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      final data = await _supabaseService.getPrescriptions();
      await _cacheService.cachePrescriptions(data);
      return data;
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      return _cacheService.getCachedPrescriptions();
    }
  }

  Stream<Map<String, dynamic>?> getProfileStream() => _supabaseService.getProfileStream();
  
  Future<void> updateProfile(Map<String, dynamic> data) => _supabaseService.updateProfile(data);
  
  Future<void> saveConditions(List<String> conditions) => _supabaseService.saveConditions(conditions);
  
  Future<void> addPrescription(Map<String, dynamic> data) => _supabaseService.addPrescription(data);
  
  Future<int> getActivePrescriptionsCount() => _supabaseService.getActivePrescriptionsCount();
  
  Future<List<Map<String, dynamic>>> getNotifications() => _supabaseService.getNotifications();
  
  Stream<List<Map<String, dynamic>>> getNotificationsStream() => _supabaseService.getNotificationsStream();
  
  Future<void> markNotificationAsRead(String id) => _supabaseService.markNotificationAsRead(id);
}
