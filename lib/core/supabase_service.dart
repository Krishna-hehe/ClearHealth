import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'services/log_service.dart';
import 'package:uuid/uuid.dart';

import 'services/input_validation_service.dart';

class SupabaseService {
  final SupabaseClient client;
  final InputValidationService validator;

  SupabaseService(this.client, this.validator);

  // MFA Operations
  Future<AuthMFAEnrollResponse> enrollMFA() async {
    return await client.auth.mfa.enroll(factorType: FactorType.totp);
  }

  Future<AuthMFAVerifyResponse> verifyMFA({
    required String factorId,
    required String code,
  }) async {
    final challenge = await client.auth.mfa.challenge(factorId: factorId);
    return await client.auth.mfa.verify(
      factorId: factorId,
      challengeId: challenge.id,
      code: code,
    );
  }

  Future<void> removeMfaFactor(String factorId) async {
    await client.auth.mfa.unenroll(factorId);
  }

  Future<AuthMFAListFactorsResponse> getMFAFactors() async {
    return await client.auth.mfa.listFactors();
  }

  // Database Operations (Examples)
  Future<List<Map<String, dynamic>>> getLabResults({
    int limit = 10,
    int offset = 0,
    String? profileId,
  }) async {
    try {
      // Start the query chain
      var queryBuilder = client.from('lab_results').select();

      // Apply filter if needed. Note: eq returns a builder we must capture.
      if (profileId != null && profileId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('profile_id', profileId);
      }

      // Apply modifiers
      return await queryBuilder
          .order('date', ascending: false)
          .range(offset, offset + limit - 1);
    } catch (e) {
      AppLogger.debug('Supabase fetch failed: $e');
      rethrow; // Let repository handle fallback
    }
  }

  Future<void> uploadLabResult(Map<String, dynamic> data) async {
    await client.from('lab_results').insert(data);
  }

  Future<void> deleteLabResult(String id) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('lab_results')
        .delete()
        .eq('id', id)
        .eq('user_id', client.auth.currentUser!.id);
  }

  // Profile Management
  Future<Map<String, dynamic>?> getProfile() async {
    if (client.auth.currentUser == null) return null;
    try {
      return await client
          .from('profiles')
          .select()
          .eq('id', client.auth.currentUser!.id)
          .single();
    } catch (e) {
      AppLogger.debug('Supabase fetch failed: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getProfileStream() {
    if (client.auth.currentUser == null) return Stream.value(null);
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', client.auth.currentUser!.id)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  Future<void> saveConditions(List<String> conditions) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('profiles')
        .update({'conditions': conditions})
        .eq('id', client.auth.currentUser!.id);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;

    // Sanitize input data
    final sanitizedData = _sanitizeMap(data);

    // Use upsert to create the profile if it doesn't exist
    await client.from('profiles').upsert({
      'id': client.auth.currentUser!.id,
      'user_id': client.auth.currentUser!.id,
      ...sanitizedData,
    });
  }

  Future<void> updateProfileData(String id, Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;
    final sanitizedData = _sanitizeMap(data);
    await client
        .from('profiles')
        .update(sanitizedData)
        .eq('id', id)
        .eq('user_id', client.auth.currentUser!.id);
  }

  // Phase 3: Family Profiles Support
  Future<List<Map<String, dynamic>>> getProfiles() async {
    if (client.auth.currentUser == null) return [];
    try {
      // Fetch all profiles linked to this user account
      return await client
          .from('profiles')
          .select()
          .eq('user_id', client.auth.currentUser!.id);
    } catch (e) {
      AppLogger.debug('Supabase getProfiles failed: $e');
      // Fallback for transition period: return single profile if generic fetch fails
      // This handles case where schema might not fully support multiple rows yet or column name mismatch
      try {
        final single = await getProfile();
        return single != null ? [single] : [];
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> createProfile(Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;
    // Helper to ensure user_id is set
    final profileData = {...data, 'user_id': client.auth.currentUser!.id};
    await client.from('profiles').insert(profileData);
  }

  Future<void> deleteProfile(String profileId) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('profiles')
        .delete()
        .eq('id', profileId)
        .eq('user_id', client.auth.currentUser!.id); // Security check
  }

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    if (client.auth.currentUser == null) return [];
    try {
      return await client
          .from('prescriptions')
          .select()
          .eq('user_id', client.auth.currentUser!.id);
    } catch (e) {
      AppLogger.debug('Error fetching prescriptions: $e');
      rethrow;
    }
  }

  Future<void> addPrescription(Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;
    await client.from('prescriptions').insert({
      ...data,
      'user_id': client.auth.currentUser!.id,
    });
  }

  Future<void> updatePrescription(String id, Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('prescriptions')
        .update(data)
        .eq('id', id)
        .eq('user_id', client.auth.currentUser!.id);
  }

  Future<void> deletePrescription(String id) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('prescriptions')
        .delete()
        .eq('id', id)
        .eq('user_id', client.auth.currentUser!.id);
  }

  // Medication Reminders (Phase 4)
  Future<List<Map<String, dynamic>>> getMedications({String? profileId}) async {
    if (client.auth.currentUser == null) return [];
    try {
      var query = client.from('medications').select('*, reminder_schedules(*)');
      if (profileId != null) {
        query = query.eq('profile_id', profileId);
      } else {
        // Default to fetching for the user if no profile specified, OR fetch all for user
        query = query.eq('user_id', client.auth.currentUser!.id);
      }
      final response = await query;
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      AppLogger.debug('Error fetching medications: $e');
      rethrow;
    }
  }

  Future<void> createMedication(Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;

    // transactional insert not easily supported without RPC, so we do two steps or use a single insert with nested data if Supabase supports it (it does for some cases, but safer to do separate for now or RPC).
    // Actually Supabase supports deep inserts if configured, but let's stick to standard inserts for safety.
    // Wait, deep insert is cleaner. Let's try deep insert structure: { ..., reminder_schedules: [...] }
    // functionality depends on Foreign Keys.
    // For now, I'll assume standard separate inserts for reliability.

    final medication = {...data};
    final schedules = medication.remove('reminder_schedules') as List?;

    final user = client.auth.currentUser!;
    medication['user_id'] = user.id;

    final response = await client
        .from('medications')
        .insert(medication)
        .select()
        .single();
    final medId = response['id'];

    if (schedules != null && schedules.isNotEmpty) {
      final List<Map<String, dynamic>> schedulesData = [];
      for (var s in schedules) {
        schedulesData.add({...s, 'medication_id': medId});
      }
      await client.from('reminder_schedules').insert(schedulesData);
    }
  }

  Future<void> updateMedication(String id, Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;

    final modification = {...data};
    final schedules = modification.remove('reminder_schedules') as List?;

    await client.from('medications').update(modification).eq('id', id);

    if (schedules != null) {
      // Replace schedules strategy: Delete all for this medication and re-insert
      // This is simplest for "edit" logic
      await client.from('reminder_schedules').delete().eq('medication_id', id);

      if (schedules.isNotEmpty) {
        final List<Map<String, dynamic>> schedulesData = [];
        for (var s in schedules) {
          schedulesData.add({...s, 'medication_id': id});
        }
        await client.from('reminder_schedules').insert(schedulesData);
      }
    }
  }

  Future<void> deleteMedication(String id) async {
    if (client.auth.currentUser == null) return;
    // Cascade delete should handle schedules if DB configured, but we can delete manually to be safe
    await client.from('reminder_schedules').delete().eq('medication_id', id);
    await client.from('medications').delete().eq('id', id);
  }

  Future<int> getActivePrescriptionsCount() async {
    if (client.auth.currentUser == null) return 0;
    try {
      final response = await client
          .from('prescriptions')
          .select('id')
          .eq('user_id', client.auth.currentUser!.id)
          .eq('is_active', true)
          .count();
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getTrendData(String testName) async {
    if (client.auth.currentUser == null) return [];
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
              'value':
                  double.tryParse(
                    match['result_value']?.toString() ??
                        match['result']?.toString() ??
                        '0',
                  ) ??
                  0.0,
              'unit': match['unit'],
              'reference': match['reference_range'] ?? match['reference'],
            });
          }
        }
      }
      // Sort by date ascending for charts
      trendPoints.sort(
        (a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
      );
      return trendPoints;
    } catch (e) {
      AppLogger.debug('Error fetching trend data: $e');
      return [];
    }
  }

  Future<List<String>> getDistinctTests() async {
    if (client.auth.currentUser == null) return [];
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
      AppLogger.debug('Error fetching distinct tests: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (client.auth.currentUser == null) return [];
    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', client.auth.currentUser!.id)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      AppLogger.debug('Error fetching notifications: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    if (client.auth.currentUser == null) return Stream.value([]);
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Map<String, dynamic>.from(e)).toList());
  }

  Future<void> markNotificationAsRead(String id) async {
    if (client.auth.currentUser == null) return;
    try {
      await client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      AppLogger.debug('Error marking notification as read: $e');
    }
  }

  Future<void> createLabResult(Map<String, dynamic> data) async {
    if (client.auth.currentUser == null) return;
    try {
      final List<dynamic> testResults = data['test_results'] ?? [];
      final abnormalCount = testResults.where((t) {
        final s = t['status']?.toString().toLowerCase() ?? '';
        return s == 'abnormal' || s == 'high' || s == 'low';
      }).length;

      final status = abnormalCount > 0 ? 'Abnormal' : 'Normal';

      // Sanitize inputs
      final sanitizedLabName = validator.sanitizeInput(
        data['lab_name']?.toString() ?? 'Manual Upload',
      );

      await client.from('lab_results').insert({
        'user_id': client.auth.currentUser!.id,
        'lab_name': sanitizedLabName,
        'date': data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
        'status': status,
        'test_count': testResults.length,
        'abnormal_count': abnormalCount,
        'test_results':
            testResults, // structured data, tough to sanitize recursively, assumed generated by system/AI? User might edit manual results.
        'storage_path': data['storage_path'],
      });

      // Trigger notification
      await NotificationService().showNotification(
        DateTime.now().millisecond,
        'Upload Complete',
        'Your lab report has been successfully processed.',
      );
    } catch (e) {
      AppLogger.debug('Error creating lab result: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHealthCircles() async {
    if (client.auth.currentUser == null) return [];
    try {
      final response = await client
          .from('health_circles')
          .select('*, members:health_circle_members(*, profiles(*))')
          .order('created_at', ascending: false);

      return (response as List).map((circle) {
        final membersRaw = circle['members'] as List? ?? [];
        final members = membersRaw.map((m) {
          final profile = m['profiles'];
          String name = 'Unknown';
          if (profile != null && profile is Map) {
            name =
                '${profile["first_name"] ?? ""} ${profile["last_name"] ?? ""}'
                    .trim();
            if (name.isEmpty) name = profile['email'] ?? 'Unknown';
          } else if (m['email'] != null) {
            name = m['email'];
          }

          return {
            'name': name,
            'role': m['role'],
            'status': m['status'],
            'permissions': m['permissions'],
            'email':
                m['email'] ??
                (profile != null && profile is Map ? profile['email'] : ''),
            'user_id': m['user_id'],
          };
        }).toList();

        return {
          'id': circle['id'],
          'name': circle['name'],
          'owner_id': circle['owner_id'],
          'members': members,
        };
      }).toList();
    } catch (e) {
      AppLogger.debug('Error fetching health circles: $e');
      return [];
    }
  }

  Future<void> updateHealthCircles(List<Map<String, dynamic>> circles) async {
    AppLogger.debug(
      'updateHealthCircles is deprecated in favor of relational operations',
    );
  }

  Future<void> createHealthCircle(String name) async {
    if (client.auth.currentUser == null) return;
    try {
      final user = client.auth.currentUser!;
      final circle = await client
          .from('health_circles')
          .insert({'name': name, 'owner_id': user.id})
          .select()
          .single();

      await client.from('health_circle_members').insert({
        'circle_id': circle['id'],
        'user_id': user.id,
        'role': 'Admin',
        'permissions': 'Full Access',
        'status': 'Active',
      });
    } catch (e) {
      AppLogger.debug('Error creating circle: $e');
      rethrow;
    }
  }

  Future<void> inviteMember(String circleId, String email, String role) async {
    if (client.auth.currentUser == null) return;
    await client.from('health_circle_members').insert({
      'circle_id': circleId,
      'email': email,
      'role': role,
      'status': 'Pending',
      'permissions': 'Read-Only', // Default
    });
  }

  Future<void> updateMemberPermissions(
    String circleId,
    String userId,
    String permissions,
  ) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('health_circle_members')
        .update({'permissions': permissions})
        .eq('circle_id', circleId)
        .eq('user_id', userId);
  }

  Future<void> joinCircle(String circleId) async {
    if (client.auth.currentUser == null) return;
    await client.rpc(
      'join_health_circle',
      params: {'circle_id_param': circleId},
    );
  }

  Future<void> deleteAccountData() async {
    if (client.auth.currentUser == null) return;
    await client.rpc('delete_account_data');
  }

  Future<String> generateShareLink() async {
    if (client.auth.currentUser == null) throw Exception('User not logged in');
    final token = await client.rpc<String>('generate_share_link');
    return token;
  }

  Future<void> logAccess({
    required String action,
    String? resourceId,
    Map<String, dynamic>? metadata,
  }) async {
    if (client.auth.currentUser == null) return;
    try {
      await client.from('access_logs').insert({
        'user_id': client.auth.currentUser!.id,
        'action': action,
        'resource_id': resourceId,
        'metadata': metadata,
      });
    } catch (e) {
      AppLogger.debug('Failed to log access: $e');
    }
  }

  // Doctor Mode / Share Link
  Future<String> createShareLink({
    required String profileId,
    Duration duration = const Duration(days: 1),
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to share results');
    }

    final token = const Uuid().v4(); // Generate a unique token
    final expiresAt = DateTime.now().toUtc().add(duration);

    await client.from('shared_links').insert({
      'user_id': user.id,
      'profile_id': profileId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'permissions': {'view_labs': true}, // Default permissions
    });

    return token;
  }

  Future<Map<String, dynamic>> getSharedData(String token) async {
    try {
      final response = await client.rpc(
        'get_shared_data',
        params: {'link_token': token},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      AppLogger.debug('Failed to fetch shared data: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    var sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        sanitized[key] = validator.sanitizeInput(value);
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
}
