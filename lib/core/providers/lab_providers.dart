import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lab_repository.dart';
import 'core_providers.dart';
import '../cache_service.dart';
import '../models.dart';

final labRepositoryProvider = Provider<LabRepository>((ref) {
  return LabRepository(
    ref.watch(supabaseServiceProvider), 
    CacheService(),
    ref.watch(storageServiceProvider),
  );
});

final labResultsProvider = AsyncNotifierProvider<LabResultsNotifier, List<LabReport>>(LabResultsNotifier.new);

class LabResultsNotifier extends AsyncNotifier<List<LabReport>> {
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<LabReport>> build() async {
    _currentPage = 0;
    _hasMore = true;
    final repository = ref.watch(labRepositoryProvider);
    return repository.getLabResults(limit: _pageSize, offset: 0);
  }

  Future<void> fetchNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    state = AsyncValue.data(state.value ?? []); // Trigger rebuild to show loading at bottom if needed

    try {
      final repository = ref.read(labRepositoryProvider);
      final nextPage = _currentPage + 1;
      final results = await repository.getLabResults(
        limit: _pageSize, 
        offset: nextPage * _pageSize,
      );

      if (results.isEmpty || results.length < _pageSize) {
        _hasMore = false;
      }

      _currentPage = nextPage;
      state = AsyncValue.data([...state.value ?? [], ...results]);
    } catch (e, st) {
      debugPrint('Error fetching next page: $e');
      // We don't change state to error to keep existing results visible
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _currentPage = 0;
      _hasMore = true;
      return ref.read(labRepositoryProvider).getLabResults(limit: _pageSize, offset: 0);
    });
  }
}

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
  final reports = await ref.watch(recentLabResultsProvider.future);
  if (reports.isEmpty) return 'No recent lab reports found for analysis.';
  
  final aiService = ref.read(aiServiceProvider);
  return aiService.getBatchSummary(reports.map((r) => r.toJson()).toList());
});

final distinctTestsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(labRepositoryProvider);
  return repository.getDistinctTests();
});

final trendDataProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, testName) async {
  final repository = ref.watch(labRepositoryProvider);
  return repository.getTrendData(testName);
});
