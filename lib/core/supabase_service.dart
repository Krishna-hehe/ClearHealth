import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // Authentication
  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // Database Operations (Examples)
  Future<List<Map<String, dynamic>>> getLabResults({int limit = 10}) async {
    try {
      final response = await client
          .from('lab_results')
          .select()
          .order('date', ascending: false)
          .limit(limit);
      
      await CacheService().cacheLabResults(response);
      return response;
    } catch (e) {
      debugPrint('Supabase fetch failed, falling back to cache: $e');
      return CacheService().getCachedLabResults();
    }
  }

  Future<void> uploadLabResult(Map<String, dynamic> data) async {
    await client.from('lab_results').insert(data);
  }

  // Profile Management
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      await CacheService().cacheProfile(response);
      return response;
    } catch (e) {
      debugPrint('Supabase fetch failed, falling back to cache: $e');
      return CacheService().getCachedProfile();
    }
  }

  Stream<Map<String, dynamic>?> getProfileStream() {
    if (currentUser == null) return Stream.value(null);
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', currentUser!.id)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  Future<void> saveConditions(List<String> conditions) async {
    if (currentUser == null) return;
    await client.from('profiles').update({'conditions': conditions}).eq('id', currentUser!.id);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await client.from('profiles').update(data).eq('id', currentUser!.id);
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    if (currentUser == null) return [];
    try {
      final response = await client
          .from('prescriptions')
          .select()
          .eq('user_id', currentUser!.id);
      
      await CacheService().cachePrescriptions(response);
      return response;
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      return CacheService().getCachedPrescriptions();
    }
  }

  Future<void> addPrescription(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await client.from('prescriptions').insert({...data, 'user_id': currentUser!.id});
  }

  Future<int> getActivePrescriptionsCount() async {
    if (currentUser == null) return 0;
    try {
      final response = await client
          .from('prescriptions')
          .select('id')
          .eq('user_id', currentUser!.id)
          .eq('is_active', true)
          .count();
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getTrendData(String testName) async {
    if (currentUser == null) return [];
    try {
      final results = await getLabResults(limit: 50); // Fetch more for trends
      List<Map<String, dynamic>> trendPoints = [];
      
      for (var report in results) {
        final date = report['date'];
        final testResults = report['test_results'] as List?;
        if (testResults != null) {
          final match = testResults.firstWhere(
            (t) => (t['test_name'] ?? t['name']) == testName,
            orElse: () => null,
          );
          if (match != null) {
            trendPoints.add({
              'date': date,
              'value': double.tryParse(match['result_value']?.toString() ?? match['result']?.toString() ?? '0') ?? 0.0,
              'unit': match['unit'],
              'reference': match['reference_range'] ?? match['reference'],
            });
          }
        }
      }
      // Sort by date ascending for charts
      trendPoints.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
      return trendPoints;
    } catch (e) {
      debugPrint('Error fetching trend data: $e');
      return [];
    }
  }

  Future<List<String>> getDistinctTests() async {
    if (currentUser == null) return [];
    try {
      final results = await getLabResults(limit: 50);
      Set<String> testNames = {};
      for (var report in results) {
        final testResults = report['test_results'] as List?;
        if (testResults != null) {
          for (var t in testResults) {
            final name = t['test_name'] ?? t['name'];
            if (name != null) testNames.add(name);
          }
        }
      }
      return testNames.toList()..sort();
    } catch (e) {
      debugPrint('Error fetching distinct tests: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (currentUser == null) return [];
    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    if (currentUser == null) return Stream.value([]);
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
  }

  Future<void> markNotificationAsRead(String id) async {
    if (currentUser == null) return;
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> createLabResult(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    try {
      final List<dynamic> testResults = data['test_results'] ?? [];
      final status = testResults.any((t) => (t['status']?.toString().toLowerCase() ?? '') == 'high' || (t['status']?.toString().toLowerCase() ?? '') == 'low') 
          ? 'Abnormal' 
          : 'Normal';

      await client.from('lab_results').insert({
        'user_id': currentUser!.id,
        'lab_name': data['lab_name'] ?? 'Manual Upload',
        'date': data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
        'status': status,
        'test_count': testResults.length,
        'test_results': testResults,
      });
    } catch (e) {
      debugPrint('Error creating lab result: $e');
      rethrow;
    }
  }
}
