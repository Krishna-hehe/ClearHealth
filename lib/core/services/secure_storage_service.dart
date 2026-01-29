import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  // Create storage
  // On web, we need to set mOptions to use non-encrypted storage if necessary,
  // but for HIPAA we ideally want encryption.
  // Note: flutter_secure_storage on web uses localStorage which is NOT secure by default without wrapping.
  // However, for this MVP implementation we will use the standard setup.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences: true, // Deprecated and ignored in v9+
    ),
  );

  static Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error writing to secure storage: $e');
    }
  }

  static Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('Error reading from secure storage: $e');
      return null;
    }
  }

  static Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('Error deleting from secure storage: $e');
    }
  }

  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error deleting all from secure storage: $e');
    }
  }
}
