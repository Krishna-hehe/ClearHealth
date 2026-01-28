import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class DashboardStats {
  final int totalReports;
  final int totalAbnormalTests;
  final int reportsNeedingAttention;
  final double normalPct;
  final List<Map<String, dynamic>> abnormalTests;

  DashboardStats({
    this.totalReports = 0,
    this.totalAbnormalTests = 0,
    this.reportsNeedingAttention = 0,
    this.normalPct = 100.0,
    this.abnormalTests = const [],
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final resultsAsync = ref.watch(labResultsProvider);

  return resultsAsync.maybeWhen(
    data: (results) {
      if (results.isEmpty) return DashboardStats();

      int totalReports = results.length;
      int totalAbnormalTests = results.fold(
        0,
        (sum, r) => sum + r.abnormalCount,
      );
      int reportsNeedingAttention = results
          .where((r) => r.abnormalCount > 0)
          .length;
      int totalTests = results.fold(0, (sum, r) => sum + r.testCount);

      double normalPct = totalTests > 0
          ? ((totalTests - totalAbnormalTests) / totalTests * 100)
          : 100.0;

      // Extract and sort abnormal tests
      List<Map<String, dynamic>> abnormalTests = [];
      for (var report in results) {
        if (report.testResults != null) {
          for (var test in report.testResults!) {
            if (test.status != 'Normal') {
              abnormalTests.add({
                'test': test,
                'date': report.date,
                'lab': report.labName,
              });
            }
          }
        }
      }
      abnormalTests.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      return DashboardStats(
        totalReports: totalReports,
        totalAbnormalTests: totalAbnormalTests,
        reportsNeedingAttention: reportsNeedingAttention,
        normalPct: normalPct,
        abnormalTests: abnormalTests,
      );
    },
    orElse: () => DashboardStats(),
  );
});

final dashboardWelcomeNameProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?['first_name'] ?? 'User',
    orElse: () => 'User',
  );
});
