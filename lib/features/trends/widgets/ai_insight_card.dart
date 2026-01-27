import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../core/models.dart';
import 'package:intl/intl.dart';

class AiInsightCard extends ConsumerStatefulWidget {
  final Map<String, List<LabReport>> data;
  final List<String> markers;

  const AiInsightCard({
    super.key,
    required this.data,
    required this.markers,
  });

  @override
  ConsumerState<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<AiInsightCard> {
  String? _analysis;
  bool _isLoading = false;

  @override
  void didUpdateWidget(covariant AiInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _analysis = null; // Reset on marker change
    }
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      // Convert map to simple history for AI
      // Just take last 5 points for each marker to save tokens/context
      final simplifiedData = <String, dynamic>{};
      
      widget.data.forEach((key, list) {
        // Take last 5 sorted by date
        final sorted = List<LabReport>.from(list)..sort((a, b) => b.date.compareTo(a.date));
        final recent = sorted.take(5).map((r) {
          final test = r.testResults?.firstWhere((t) => t.name == key, orElse: () => TestResult(name: '', loinc: '', result: '', unit: '', reference: '', status: ''));
          return test != null && test.result.isNotEmpty ? '${DateFormat('yyyy-MM-dd').format(r.date)}: ${test.result} ${test.unit}' : null;
        }).where((e) => e != null).cast<String>().toList();
        simplifiedData[key] = recent;
      });

      final result = await aiService.getTrendCorrelationAnalysis(simplifiedData);
      if (mounted) setState(() => _analysis = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate insights')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Trend Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    'Correlation & Trajectory Insights',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_analysis == null && !_isLoading)
            Center(
              child: ElevatedButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Analyze Relationship'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            )
          else if (_isLoading)
            const Center(
              child: Column(
                children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Analyzing trends...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            MarkdownBody(
              data: _analysis!,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF374151)),
                strong: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ),
        ],
      ),
    );
  }
}
