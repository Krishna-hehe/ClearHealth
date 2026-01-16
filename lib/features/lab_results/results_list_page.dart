import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../core/navigation.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/pdf_service.dart';



class ResultsListPage extends ConsumerWidget {
  const ResultsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labResultsAsync = ref.watch(labResultsProvider);
    final isComparisonMode = ref.watch(isComparisonModeProvider);
    final selectedReportsForComparison = ref.watch(selectedComparisonReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref, isComparisonMode, selectedReportsForComparison),
        const SizedBox(height: 24),
        labResultsAsync.when(
          data: (results) {
            final data = results.isEmpty ? _getMockResults() : results;
            return Column(
              children: [
                _buildPdfDownloadCard(context, data),
                const SizedBox(height: 32),
                ...data.map((result) => _buildResultCard(context, ref, result, isComparisonMode, selectedReportsForComparison)),
              ],
            );
          },
          error: (err, stack) => Center(child: Text('Error: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isComparisonMode, List<LabReport> selectedReports) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Lab History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            if (isComparisonMode) ...[
              Text(
                '${selectedReports.length} selected',
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: selectedReports.length >= 2 
                  ? () => ref.read(navigationProvider.notifier).state = NavItem.comparison
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Compare Now'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ref.read(isComparisonModeProvider.notifier).state = false;
                  ref.read(selectedComparisonReportsProvider.notifier).state = [];
                },
                child: const Text('Cancel'),
              ),
            ] else 
              OutlinedButton.icon(
                icon: const Icon(Icons.compare_arrows, size: 16),
                label: const Text('Compare Results'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => ref.read(isComparisonModeProvider.notifier).state = true,
              ),
          ],
        ),
      ],
    );
  }

  // Temporary mock data adapter to LabReport for smooth transition
  List<LabReport> _getMockResults() {
     return [
      LabReport(id: '1', date: DateTime(2025, 11, 14), status: 'Abnormal', testCount: 28, labName: 'INDIAN RED CROSS SOCIETY AHMEDABAD DISTRICT BRANCH'),
      LabReport(id: '2', date: DateTime(2024, 9, 17), status: 'Normal', testCount: 18, labName: 'INDIAN RED CROSS SOCIETY AHMEDABAD DISTRICT BRANCH'),
      LabReport(id: '3', date: DateTime(2024, 7, 10), status: 'Normal', testCount: 22, labName: 'SUN PATHOLOGY LABORATORY & RESEARCH INSTITUTE'),
      LabReport(id: '4', date: DateTime(2011, 8, 25), status: 'Abnormal', testCount: 18, labName: 'GNU Solidario Hospital'),
    ];
  }


  Widget _buildPdfDownloadCard(BuildContext context, List<LabReport> results) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Includes known conditions, lab tests, and AI summaries.',
                  style: TextStyle(color: AppColors.secondary, fontSize: 13),
                ),
                Text(
                  'Manage conditions.',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _buildDateField(context, 'From', '13-10-2025'),
          const SizedBox(width: 12),
          _buildDateField(context, 'To', '13-01-2026'),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            icon: const Icon(FontAwesomeIcons.download, size: 14),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => PdfService.generateSummaryPdf(results),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(date, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today, size: 14, color: AppColors.secondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, WidgetRef ref, LabReport result, bool isComparisonMode, List<LabReport> selectedReports) {
    final status = result.status;
    final isAbnormal = status == 'Abnormal';
    final isSelected = selectedReports.any((r) => r.id == result.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (isComparisonMode) {
            final newList = List<LabReport>.from(selectedReports);
            if (isSelected) {
              newList.removeWhere((r) => r.id == result.id);
            } else {
              if (newList.length < 3) {
                newList.add(result);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select up to 3 reports for comparison')),
                );
              }
            }
            ref.read(selectedComparisonReportsProvider.notifier).state = newList;
          } else {
            ref.read(selectedReportProvider.notifier).state = result;
            ref.read(navigationProvider.notifier).state = NavItem.resultExpanded;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isComparisonMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    final newList = List<LabReport>.from(selectedReports);
                    if (val == true) {
                      if (newList.length < 3) newList.add(result);
                    } else {
                      newList.removeWhere((r) => r.id == result.id);
                    }
                    ref.read(selectedComparisonReportsProvider.notifier).state = newList;
                  },
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lab Result - ${result.date.toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.testCount} lab results found',
                      style: const TextStyle(color: AppColors.secondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAbnormal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAbnormal ? Icons.error_outline : Icons.check_circle_outline,
                      size: 14,
                      color: isAbnormal ? AppColors.danger : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: isAbnormal ? AppColors.danger : AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isComparisonMode) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.secondary, size: 20),
                  onPressed: () {
                    if (result.testResults != null) {
                      PdfService.generateLabReportPdf(result, result.testResults!);
                    }
                  },
                ),
                const Icon(Icons.chevron_right, color: AppColors.border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
