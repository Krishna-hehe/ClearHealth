import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<String?> uploadLabReport(Uint8List bytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _supabase.storage.from('lab-reports').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return path;
    } catch (e) {
      debugPrint('Error uploading lab report: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePhoto(Uint8List bytes) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Use userId as folder to match RLS: (storage.foldername(name))[1] == auth.uid()
    final path = '$userId/profile.jpg';
    
    await _supabase.storage.from('profiles').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );

    final String publicUrl = _supabase.storage.from('profiles').getPublicUrl(path);
    return publicUrl;
  }

  Future<String?> uploadPrescriptionImage(Uint8List bytes) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('prescriptions').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final String publicUrl = _supabase.storage.from('prescriptions').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading prescription image: $e');
      return null;
    }
  }
  Future<void> deleteLabReportFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _supabase.storage.from('lab-reports').remove([path]);
    } catch (e) {
      debugPrint('Error deleting lab report file from storage: $e');
    }
  }
}
