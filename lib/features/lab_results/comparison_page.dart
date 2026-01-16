import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/navigation.dart';

class ComparisonPage extends ConsumerWidget {
  const ComparisonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReports = ref.watch(selectedComparisonReportsProvider);

    if (selectedReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare_arrows, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            const Text(
              'No reports selected for comparison',
              style: TextStyle(color: AppColors.secondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(navigationProvider.notifier).state = NavItem.labResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Lab Results'),
            ),
          ],
        ),
      );
    }

    // Sort reports by date
    final sortedReports = List<LabReport>.from(selectedReports)..sort((a, b) => a.date.compareTo(b.date));

    // Get all unique test names across all reports
    final allTestNames = <String>{};
    for (var report in sortedReports) {
      if (report.testResults != null) {
        for (var test in report.testResults!) {
          allTestNames.add(test.name);
        }
      }
    }
    final sortedTestNames = allTestNames.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => ref.read(navigationProvider.notifier).state = NavItem.labResults,
            ),
            const Text(
              'Lab Result Comparison',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${sortedReports.length} Reports Selected',
              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              columnSpacing: 40,
              columns: [
                const DataColumn(
                  label: Text('Test Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                ...sortedReports.map((report) => DataColumn(
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.date.toString().split(' ')[0],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        report.labName,
                        style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                )),
              ],
              rows: sortedTestNames.map((testName) {
                return DataRow(
                  cells: [
                    DataCell(Text(testName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ...sortedReports.map((report) {
                      final test = report.testResults?.firstWhere(
                        (t) => t.name == testName,
                        orElse: () => TestResult(name: '', loinc: '', result: '', unit: '', reference: '', status: ''),
                      );
                      
                      final value = test?.result.isEmpty == true ? '-' : test?.result ?? '-';
                      final unit = test?.unit ?? '';
                      final isAbnormal = test?.status.toLowerCase().contains('high') == true || 
                                       test?.status.toLowerCase().contains('low') == true;

                      return DataCell(
                        Row(
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontWeight: isAbnormal ? FontWeight.bold : FontWeight.normal,
                                color: isAbnormal ? AppColors.danger : Colors.black,
                              ),
                            ),
                            if (unit.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(unit, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
                            ],
                            // Show trend arrow if not the first column
                            if (sortedReports.indexOf(report) > 0)
                              _buildTrendIndicator(testName, report, sortedReports[sortedReports.indexOf(report)-1]),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(String testName, LabReport current, LabReport previous) {
    final currentTest = current.testResults?.firstWhere(
      (t) => t.name == testName,
      orElse: () => TestResult(name: '', loinc: '', result: '', unit: '', reference: '', status: ''),
    );
    final prevTest = previous.testResults?.firstWhere(
      (t) => t.name == testName,
      orElse: () => TestResult(name: '', loinc: '', result: '', unit: '', reference: '', status: ''),
    );

    if (currentTest == null || prevTest == null || currentTest.name.isEmpty || prevTest.name.isEmpty) {
      return const SizedBox.shrink();
    }

    final curVal = double.tryParse(currentTest.result);
    final preVal = double.tryParse(prevTest.result);

    if (curVal == null || preVal == null) return const SizedBox.shrink();

    if (curVal > preVal) {
      return const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Icon(Icons.trending_up, color: AppColors.danger, size: 16),
      );
    } else if (curVal < preVal) {
      return const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Icon(Icons.trending_down, color: AppColors.success, size: 16),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Icon(Icons.trending_flat, color: AppColors.secondary, size: 16),
      );
    }
  }
}
