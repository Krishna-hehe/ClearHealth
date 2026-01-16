import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _profileBox = 'profile_box';
  static const String _labResultsBox = 'lab_results_box';
  static const String _prescriptionsBox = 'prescriptions_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_profileBox);
    await Hive.openBox(_labResultsBox);
    await Hive.openBox(_prescriptionsBox);
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
