import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';
import '../../core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataExportService {
  final Ref ref;

  DataExportService(this.ref);

  Future<void> exportUserData() async {
    final supabase = ref.read(supabaseServiceProvider);

    // 1. Fetch Profile
    final profile = await supabase.getProfile();

    // 2. Fetch Lab Results
    final labs = await supabase.getLabResults(limit: 1000); // Get all

    // 3. Fetch Prescriptions
    final prescriptions = await supabase.getPrescriptions();

    // 4. Bundle Data
    final exportData = {
      'generated_at': DateTime.now().toIso8601String(),
      'profile': profile,
      'lab_results': labs,
      'prescriptions': prescriptions,
      'compliance': 'GDPR/HIPAA Data Export',
    };

    final jsonStr = jsonEncode(exportData);

    // 5. Trigger Download
    if (kIsWeb) {
      final bytes = utf8.encode(jsonStr);
      // Create Blob using JS interop
      final blob = web.Blob([bytes.toJS].toJS);

      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;

      anchor.href = url;
      anchor.download = "labsense_export_${DateTime.now().millisecond}.json";
      anchor.click();

      web.URL.revokeObjectURL(url);
    } else {
      // For mobile, we would use path_provider and share_plus
      // Keeping web-focused for now as per project type
      debugPrint('Export data generated: ${jsonStr.length} bytes');
    }
  }
}

final dataExportServiceProvider = Provider((ref) => DataExportService(ref));
