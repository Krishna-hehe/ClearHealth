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
      final response = await supabase.functions.invoke('audit-log', body: {
        'action': action.name,
        'details': details,
        'resourceId': resourceId,
      });

      if (response.status != 200) {
        throw 'Failed to log audit event: ${response.data}';
      }

      AppLogger.info('Audit Log: ${action.name} - $details');
    } catch (e) {
      // Audit logging failure should not crash the app, but should be noted
      AppLogger.error('Failed to write audit log: $e');
    }
  }
}

final auditServiceProvider = Provider((ref) => AuditService(ref));
