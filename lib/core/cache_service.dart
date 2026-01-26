import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const String _profileBox = 'profile_box_enc';
  static const String _labResultsBox = 'lab_results_box_enc';
  static const String _prescriptionsBox = 'prescriptions_box_enc';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Get or create encryption key
    final encryptionKeyString = await _secureStorage.read(key: 'hive_encryption_key');
    Uint8List encryptionKey;
    
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: 'hive_encryption_key',
        value: base64UrlEncode(key),
      );
      encryptionKey = Uint8List.fromList(key);
    } else {
      encryptionKey = base64Url.decode(encryptionKeyString);
    }

    // Open boxes with encryption
    await Hive.openBox(_profileBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(_labResultsBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(_prescriptionsBox, encryptionCipher: HiveAesCipher(encryptionKey));
  }

  // Profile Cache
  Future<void> cacheProfile(Map<String, dynamic>? profile) async {
    if (profile == null) return;
    final box = Hive.box(_profileBox);
    await box.put('current', profile);
  }

  Map<String, dynamic>? getCachedProfile() {
    final box = Hive.box(_profileBox);
    final data = box.get('current');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // Lab Results Cache
  Future<void> cacheLabResults(List<Map<String, dynamic>> results) async {
    final box = Hive.box(_labResultsBox);
    await box.put('list', results);
  }

  List<Map<String, dynamic>> getCachedLabResults() {
    final box = Hive.box(_labResultsBox);
    final data = box.get('list');
    return data != null ? List<Map<String, dynamic>>.from(data) : [];
  }

  // Prescriptions Cache
  Future<void> cachePrescriptions(List<Map<String, dynamic>> prescriptions) async {
    final box = Hive.box(_prescriptionsBox);
    await box.put('list', prescriptions);
  }

  List<Map<String, dynamic>> getCachedPrescriptions() {
    final box = Hive.box(_prescriptionsBox);
    final data = box.get('list');
    return data != null ? List<Map<String, dynamic>>.from(data) : [];
  }

  Future<void> clearAll() async {
    await Hive.box(_profileBox).clear();
    await Hive.box(_labResultsBox).clear();
    await Hive.box(_prescriptionsBox).clear();
  }
}
