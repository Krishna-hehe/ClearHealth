import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadLabReport(Uint8List bytes, String fileName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final path = 'lab_reports/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
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
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final path = 'profiles/$userId.jpg';
      
      await _supabase.storage.from('profiles').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String publicUrl = _supabase.storage.from('profiles').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }
}
