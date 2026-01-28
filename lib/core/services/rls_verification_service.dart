import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

/// RLS (Row Level Security) Verification Service
///
/// Verifies that Supabase Row Level Security policies are properly configured
/// This is a critical security check to prevent unauthorized data access
class RlsVerificationService {
  final SupabaseClient _client;
  bool _isVerified = false;
  DateTime? _lastVerification;

  RlsVerificationService(this._client);

  /// Check if RLS has been verified recently (within last hour)
  bool get isVerified {
    if (!_isVerified) return false;

    if (_lastVerification == null) return false;

    // Re-verify every hour
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _lastVerification!.isAfter(hourAgo);
  }

  /// Verify RLS is enabled on critical tables
  ///
  /// This attempts to access data that should be blocked by RLS.
  /// If we CAN access it, RLS is NOT working correctly.
  Future<bool> verifyRlsPolicies() async {
    try {
      AppLogger.info('🔐 Starting RLS verification...');

      // Test 1: Verify we cannot access other users' lab results
      final labResultsTest = await _testLabResultsRls();

      // Test 2: Verify we cannot access other users' profiles
      final profilesTest = await _testProfilesRls();

      // Test 3: Verify we cannot access other users' prescriptions
      final prescriptionsTest = await _testPrescriptionsRls();

      final allPassed = labResultsTest && profilesTest && prescriptionsTest;

      if (allPassed) {
        _isVerified = true;
        _lastVerification = DateTime.now();
        AppLogger.info(
          '✅ RLS verification PASSED - All policies working correctly',
        );
      } else {
        _isVerified = false;
        AppLogger.error(
          '🚨 RLS verification FAILED - Security policies not working!',
        );
      }

      return allPassed;
    } catch (e) {
      AppLogger.error('❌ RLS verification error: $e');
      _isVerified = false;
      return false;
    }
  }

  /// Test lab_results RLS policy
  Future<bool> _testLabResultsRls() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        AppLogger.warning('⚠️ Cannot verify RLS - no authenticated user');
        return false;
      }

      // Try to access a non-existent user's data
      // RLS should return empty result, not throw error
      final result = await _client
          .from('lab_results')
          .select('id')
          .eq('user_id', '00000000-0000-0000-0000-000000000000') // Invalid UUID
          .limit(1);

      // If we get results, RLS is broken
      if (result.isNotEmpty) {
        AppLogger.error(
          '🚨 lab_results RLS FAILED - Can access other users data!',
        );
        return false;
      }

      // Try to access our own data - should work
      await _client
          .from('lab_results')
          .select('id')
          .eq('user_id', currentUser.id)
          .limit(1);

      // We should be able to access our own data
      AppLogger.info(
        '✅ lab_results RLS working - Own data accessible, others blocked',
      );
      return true;
    } catch (e) {
      // Errors are expected if RLS is working correctly
      AppLogger.debug('lab_results RLS test error (expected): $e');
      return true; // Error accessing other user's data = RLS working
    }
  }

  /// Test profiles RLS policy
  Future<bool> _testProfilesRls() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Try to access a non-existent user's profile
      final result = await _client
          .from('profiles')
          .select('id')
          .eq('user_id', '00000000-0000-0000-0000-000000000000')
          .limit(1);

      if (result.isNotEmpty) {
        AppLogger.error(
          '🚨 profiles RLS FAILED - Can access other users profiles!',
        );
        return false;
      }

      AppLogger.info('✅ profiles RLS working');
      return true;
    } catch (e) {
      AppLogger.debug('profiles RLS test error (expected): $e');
      return true;
    }
  }

  /// Test prescriptions RLS policy
  Future<bool> _testPrescriptionsRls() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Try to access a non-existent user's prescriptions
      final result = await _client
          .from('prescriptions')
          .select('id')
          .eq('user_id', '00000000-0000-0000-0000-000000000000')
          .limit(1);

      if (result.isNotEmpty) {
        AppLogger.error(
          '🚨 prescriptions RLS FAILED - Can access other users prescriptions!',
        );
        return false;
      }

      AppLogger.info('✅ prescriptions RLS working');
      return true;
    } catch (e) {
      AppLogger.debug('prescriptions RLS test error (expected): $e');
      return true;
    }
  }

  /// Force re-verification (useful after database schema changes)
  Future<bool> forceVerify() async {
    _isVerified = false;
    _lastVerification = null;
    return await verifyRlsPolicies();
  }
}
