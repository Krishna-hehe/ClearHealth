import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../core/navigation.dart';
import '../../core/providers.dart';
import '../../core/providers/user_providers.dart';
import '../../core/pdf_service.dart';

class ShareResultsPage extends ConsumerWidget {
  const ShareResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => ref.read(navigationProvider.notifier).state = NavItem.dashboard,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Dashboard'),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        ),
        const SizedBox(height: 16),
        const Text(
          'Share Results',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Securely share your health data with doctors or family.',
          style: TextStyle(color: AppColors.secondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        _buildProfessionalPdfCard(context, ref),
        const SizedBox(height: 24),
        _buildShareOptions(context),
        const SizedBox(height: 24),
        _buildSharingHistory(),
      ],
    );
  }

  Widget _buildShareOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Secure Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Generate a temporary, encrypted link to share your records.',
            style: TextStyle(color: AppColors.secondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildOptionChip(Icons.timer_outlined, 'Expires in 24h'),
              const SizedBox(width: 8),
              _buildOptionChip(Icons.lock_outline, 'Password Protected'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Generate Share Link'),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Feature temporarily unavailable during debugging.')),
               );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildSharingHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Shares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No active share links. Generate one above to get started.',
                style: TextStyle(color: AppColors.secondary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalPdfCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Health Summary',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Generate a medical-grade PDF summary of your entire lab history with AI insights to share with your doctor.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            icon: const Icon(FontAwesomeIcons.fileMedical, size: 14),
            label: const Text('Generate PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final reports = ref.read(labResultsProvider).value ?? [];
              if (reports.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No lab reports found to generate summary.')),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating AI insights...')),
              );

              final List<Map<String, dynamic>> flatTests = [];
              for (var r in reports) {
                if (r.testResults != null) {
                  flatTests.addAll(r.testResults!.map((t) => t.toJson()));
                }
              }
              
              final aiSummary = await ref.read(aiServiceProvider).getBatchSummary(flatTests);
              await PdfService.generateSummaryPdf(reports, aiSummary: aiSummary);
            },
          ),
        ],
      ),
    );
  }
}
