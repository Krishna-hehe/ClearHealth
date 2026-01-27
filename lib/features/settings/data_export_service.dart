import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "labsense_export_${DateTime.now().millisecond}.json")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile, we would use path_provider and share_plus
      // Keeping web-focused for now as per project type
      print('Export data generated: ${jsonStr.length} bytes');
    }
  }
}

final dataExportServiceProvider = Provider((ref) => DataExportService(ref));
