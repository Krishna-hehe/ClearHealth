import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/ai_service.dart';
import '../../core/navigation.dart';

class ResultDetailPage extends ConsumerWidget {
  const ResultDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTest = ref.watch(selectedTestProvider);
    final selectedReport = ref.watch(selectedReportProvider);

    if (selectedTest == null) {
      return const Center(
        child: Text('No test selected. Please select a test from the results list.'),
      );
    }

    final testName = selectedTest.name;
    final value = double.tryParse(selectedTest.result) ?? 0.0;
    final unit = selectedTest.unit;
    final referenceRange = selectedTest.reference;

    return FutureBuilder<LabTestAnalysis>(
      future: AiService.getSingleTestAnalysis(
        testName: testName,
        value: value,
        unit: unit,
        referenceRange: referenceRange,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final analysis = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRangeBanner(context, analysis.status),
            const SizedBox(height: 24),
            _buildResultHeader(context, testName, value, unit, referenceRange, selectedReport?.date),
            const SizedBox(height: 24),
            _buildAnalysisSection(context, analysis),
            const SizedBox(height: 24),
            _buildTrendSection(context),
          ],
        );
      },
    );
  }

  Widget _buildRangeBanner(BuildContext context, String status) {
    final isNormal = status == 'Normal';
    final isHigh = status == 'High';
    final color = isNormal ? AppColors.success : (isHigh ? AppColors.danger : Colors.orange);
    final bgColor = isNormal ? AppColors.success.withOpacity(0.1) : (isHigh ? AppColors.danger.withOpacity(0.1) : Colors.orange.withOpacity(0.1));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isNormal ? Icons.check_circle_outline : Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNormal ? 'Within Normal Range' : (isHigh ? 'High - Outside Range' : 'Low - Outside Range'),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                isNormal ? 'This result falls within the typical reference range.' : 'Follow up with your doctor regarding this $status result.',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context, String name, double value, String unit, String referenceRange, DateTime? date) {
    final dateStr = date != null ? DateFormat('MMMM d, yyyy').format(date) : 'Unknown Date';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(FontAwesomeIcons.bolt, size: 16, color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const Text(
                    'LOINC: 2160-0',
                    style: TextStyle(color: AppColors.secondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildValueCard(context, 'Your Result', value.toString(), unit),
              const SizedBox(width: 16),
              _buildValueCard(context, 'Reference Range', referenceRange, ''),
              const SizedBox(width: 16),
              _buildValueCard(context, 'Test Date', dateStr, ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: const TextStyle(color: AppColors.secondary, fontSize: 14)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(BuildContext context, LabTestAnalysis analysis) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(FontAwesomeIcons.commentDots, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  const Text('Understanding Your Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoBlock(
                FontAwesomeIcons.circleQuestion,
                'What This Test Measures',
                analysis.description,
              ),
              _buildInfoBlock(
                FontAwesomeIcons.waveSquare,
                'Your Result',
                analysis.resultContext,
              ),
              _buildInfoBlock(
                FontAwesomeIcons.circleExclamation,
                'What This Means',
                analysis.meaning,
              ),
              const SizedBox(height: 8),
              const Text(
                'Common Factors That Can Affect This Test',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...analysis.factors.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.secondary))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildQuestionsSection(context, analysis.questions),
      ],
    );
  }

  Widget _buildQuestionsSection(BuildContext context, List<String> questions) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions to Ask Your Doctor',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...questions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.secondary))),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'This is educational information, not medical advice. Please discuss your results with your healthcare provider.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.secondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTrendSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.chartLine, size: 16, color: AppColors.secondary),
              const SizedBox(width: 12),
              const Text('Trend Analysis (3 results)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(FontAwesomeIcons.arrowTrendDown, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Decreasing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text('+22.3% change', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            'Your creatinine levels were stable at 1.12 mg/dL in September 2024. By November 2025, the level decreased to 0.87 mg/dL, representing a notable downward trend.',
            style: TextStyle(fontSize: 14, color: AppColors.secondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
