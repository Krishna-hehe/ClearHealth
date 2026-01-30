import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_service.dart';
import '../providers.dart';

enum AuditAction {
  login,
  logout,
  viewLabResult,
  exportData,
  updateProfile,
  deleteAccount,
  viewPrescription,
}

class AuditService {
  final Ref ref;

  AuditService(this.ref);

  Future<void> log(
    AuditAction action, {
    String? details,
    String? resourceId,
  }) async {
    try {
      final supabase = ref.read(supabaseServiceProvider).client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        AppLogger.warning('Attempted to log audit event without user: $action');
        return;
      }

      await supabase.from('audit_logs').insert({
        'user_id': user.id,
        'action': action.name,
        // 'details': details, // Removed: column does not exist
        'resource_id': resourceId,
        'timestamp': DateTime.now().toIso8601String(),
        'ip_address':
            'client-side', // In a real app, this should be done via Edge Function for accuracy
      });

      AppLogger.info('Audit Log: ${action.name} - $details');
    } catch (e) {
      // Audit logging failure should not crash the app, but should be noted
      AppLogger.error('Failed to write audit log: $e');
    }
  }
}

final auditServiceProvider = Provider((ref) => AuditService(ref));
