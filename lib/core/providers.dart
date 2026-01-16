import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import 'ai_service.dart';
import 'repositories/lab_repository.dart';
import 'models.dart';

final labRepositoryProvider = Provider<LabRepository>((ref) {
  return LabRepository();
});

final labResultsProvider = FutureProvider<List<LabReport>>((ref) async {
  final repository = ref.watch(labRepositoryProvider);
  return repository.getLabResults();
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await SupabaseService().getProfile();
});

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return SupabaseService().getProfileStream();
});

final notificationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return SupabaseService().getNotificationsStream();
});

final optimizationTipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final results = await ref.watch(labResultsProvider.future);
  if (results.isEmpty) return [];
  
  // Find abnormal tests in the latest result
  final latest = results.first; // Already sorted by date in repo? Let's assume for now or sort explicitly.
  final abnormalTests = latest.testResults?.where((t) {
    final status = t.status.toLowerCase();
    return status.contains('high') || status.contains('low');
  }).toList() ?? [];

  if (abnormalTests.isEmpty) return [];
  return AiService.getOptimizationTips(abnormalTests.map((t) => t.toJson()).toList());
});

final showOnboardingProvider = StateProvider<bool>((ref) => false);

final selectedComparisonReportsProvider = StateProvider<List<LabReport>>((ref) => []);

final isComparisonModeProvider = StateProvider<bool>((ref) => false);

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
