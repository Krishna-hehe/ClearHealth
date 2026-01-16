import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lab_repository.dart';
import 'core_providers.dart';
import '../cache_service.dart';
import '../models.dart';

final labRepositoryProvider = Provider<LabRepository>((ref) {
  return LabRepository(ref.watch(supabaseServiceProvider), CacheService());
});

final labResultsProvider = FutureProvider<List<LabReport>>((ref) async {
  final repository = ref.watch(labRepositoryProvider);
  return repository.getLabResults();
});

final recentLabResultsProvider = FutureProvider<List<LabReport>>((ref) async {
  final repository = ref.watch(labRepositoryProvider);
  return repository.getLabResults(limit: 3);
});

final optimizationTipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final results = await ref.watch(labResultsProvider.future);
  if (results.isEmpty) return [];
  
  // Find abnormal tests in the latest result
  final latest = results.first; 
  final abnormalTests = latest.testResults?.where((t) {
    final status = t.status.toLowerCase();
    return status.contains('high') || status.contains('low');
  }).toList() ?? [];

  if (abnormalTests.isEmpty) return [];
  
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getOptimizationTips(abnormalTests.map((t) => t.toJson()).toList());
});
final dashboardAiInsightProvider = FutureProvider<String>((ref) async {
  final recentResults = await ref.watch(recentLabResultsProvider.future);
  if (recentResults.isEmpty) return 'No recent lab results found. Upload a report to get AI insights.';
  
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getBatchSummary(recentResults.map((r) => r.toJson()).toList());
});
final healthHistoryAiSummaryProvider = FutureProvider<String>((ref) async {
  final reports = await ref.watch(labResultsProvider.future);
  if (reports.isEmpty) return 'No lab reports found for analysis.';
  
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getBatchSummary(reports.map((r) => r.toJson()).toList());
});

final distinctTestsProvider = FutureProvider<List<String>>((ref) async {
  final reports = await ref.watch(labResultsProvider.future);
  if (reports.isEmpty) return [];
  
  final tests = <String>{};
  for (var report in reports) {
    if (report.testResults != null) {
      for (var test in report.testResults!) {
        tests.add(test.name);
      }
    }
  }
  return tests.toList()..sort();
});

final trendDataProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, testName) async {
  final repository = ref.watch(labRepositoryProvider);
  return repository.getTrendData(testName);
});
