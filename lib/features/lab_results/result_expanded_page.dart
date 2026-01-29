import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/navigation.dart';
import '../../core/models.dart';
import '../../core/providers.dart';

class ResultExpandedPage extends ConsumerStatefulWidget {
  const ResultExpandedPage({super.key});

  @override
  ConsumerState<ResultExpandedPage> createState() => _ResultExpandedPageState();
}

class _ResultExpandedPageState extends ConsumerState<ResultExpandedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logAccess();
    });
  }

  void _logAccess() {
    final report = ref.read(selectedReportProvider);
    if (report != null) {
      ref
          .read(supabaseServiceProvider)
          .logAccess(
            action: 'View Lab Report',
            resourceId: report.id,
            metadata: {
              'lab_name': report.labName,
              'test_count': report.testCount,
            },
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(selectedReportProvider);

    if (report == null) {
      return const Center(
        child: Text(
          'No lab report selected. Please select one from the results list.',
        ),
      );
    }

    final tests = report.testResults ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, report),
            if (tests.isNotEmpty) _buildAiSummary(context, tests, ref),
            if (tests.isNotEmpty)
              _buildTable(context, tests, ref)
            else
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: AppColors.border,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No detailed test data found for this report.',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, LabReport report) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.fileLines,
              size: 20,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(report.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.hospital,
                      size: 12,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lab: ${report.labName}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${report.testCount} tests',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Report'),
                  content: const Text(
                    'Are you sure you want to delete this lab report? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await ref
                      .read(labRepositoryProvider)
                      .deleteLabResult(
                        report.id,
                        storagePath: report.storagePath,
                      );
                  ref.invalidate(labResultsProvider);
                  ref.invalidate(recentLabResultsProvider);
                  ref.read(navigationProvider.notifier).state =
                      NavItem.labResults;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report deleted successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting report: $e')),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.secondary),
            onPressed: () => ref.read(navigationProvider.notifier).state =
                NavItem.labResults,
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummary(
    BuildContext context,
    List<TestResult> tests,
    WidgetRef ref,
  ) {
    final testData = tests
        .map(
          (t) => <String, dynamic>{
            'name': t.name,
            'result': t.result,
            'reference': t.reference,
          },
        )
        .toList();

    return FutureBuilder<String>(
      future: ref.read(aiServiceProvider).getBatchSummary(testData),
      builder: (context, snapshot) {
        final summary = snapshot.data ?? 'Analyzing your results with AI...';
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<TestResult> tests,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1),
          ...tests.map((test) => _buildTableRow(context, test, ref)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'TEST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'RESULT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'REFERENCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, TestResult test, WidgetRef ref) {
    final bool isAbnormal = test.status != 'Normal';

    return InkWell(
      onTap: () {
        ref.read(selectedTestProvider.notifier).state = test;
        ref.read(navigationProvider.notifier).state = NavItem.resultDetail;
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'LOINC: ${test.loinc}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: test.result,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isAbnormal
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' ${test.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                test.reference,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAbnormal
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAbnormal
                        ? AppColors.danger.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAbnormal
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 12,
                      color: isAbnormal
                          ? AppColors.danger
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      test.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: isAbnormal
                            ? AppColors.danger
                            : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: const Text(
                'Details',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
