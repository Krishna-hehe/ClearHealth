import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/navigation.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create 6 staggered animations
    _animations = List.generate(6, (index) {
      double start = index * 0.1;
      double end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    
    // Trigger animation when data is ready
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final recentResultsAsync = ref.watch(recentLabResultsProvider);
    final prescriptionsCountAsync = ref.watch(activePrescriptionsCountProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (profile) => recentResultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (recentResults) => prescriptionsCountAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (pCount) {
             final firstName = profile?['first_name'] ?? 'User';
             final conditions = profile?['conditions'] as List? ?? [];
             
             return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedItem(0, _buildWelcomeHeader(firstName)),
                    const SizedBox(height: 32),
                    _buildAnimatedItem(1, _buildQuickStats(recentResults, conditions.length, pCount)),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildAnimatedItem(2, _buildAiInsightsCard(recentResults)),
                              const SizedBox(height: 24),
                              _buildAnimatedItem(3, _buildRecentResults(recentResults)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildAnimatedItem(4, _buildHealthTipsCard(recentResults)),
                              const SizedBox(height: 24),
                              _buildAnimatedItem(5, _buildUpcomingTasks()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return FadeTransition(
      opacity: _animations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animations[index]),
        child: child,
      ),
    );
  }

  Widget _buildWelcomeHeader(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $firstName',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Here is what is happening with your health today.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(List<LabReport> recentResults, int conditionsCount, int prescriptionsCount) {
    String lastResultDate = 'N/A';
    String lastResultStatus = 'N/A';
    Color lastResultColor = AppColors.secondary;
    Color lastResultBg = const Color(0xFFF3F4F6);

    if (recentResults.isNotEmpty) {
      final last = recentResults.first;
      lastResultDate = DateFormat('MMM d').format(last.date);
      lastResultStatus = last.status;
      
      if (lastResultStatus == 'Abnormal') {
        lastResultColor = AppColors.danger;
        lastResultBg = const Color(0xFFFEF2F2);
      } else if (lastResultStatus == 'Normal') {
        lastResultColor = AppColors.success;
        lastResultBg = const Color(0xFFF0FDF4);
      }
    }

    return Row(
      children: [
        _buildStatCard('Last Lab Result', lastResultDate, lastResultStatus, Icons.description_outlined, lastResultBg, lastResultColor),
        const SizedBox(width: 16),
        _buildStatCard('Known Conditions', '$conditionsCount Active', 'Stable', Icons.favorite_border, const Color(0xFFF0FDF4), AppColors.success),
        const SizedBox(width: 16),
        _buildStatCard('Active Medications', '$prescriptionsCount Prescriptions', 'On Track', Icons.medication_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String status, IconData icon, Color bgColor, Color statusColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: statusColor),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightsCard(List<LabReport> recentResults) {
    return Consumer(
      builder: (context, ref, child) {
        final insightAsync = ref.watch(dashboardAiInsightProvider);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withAlpha((0.3 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(FontAwesomeIcons.robot, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'AI Health Insight',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              insightAsync.when(
                data: (insight) => Text(
                  insight,
                  style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontSize: 14, height: 1.5),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, s) => Text('Failed to load insight: $e', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                   ref.read(navigationProvider.notifier).state = NavItem.healthChat;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View Full Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRecentResults(List<LabReport> recentResults) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Lab Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () => ref.read(navigationProvider.notifier).state = NavItem.labResults,
                child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentResults.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('No results yet.', style: TextStyle(color: AppColors.secondary)),
             )
          else
            ...recentResults.map((result) {
              final dateStr = DateFormat('MMM d, yyyy').format(result.date);
              final status = result.status;
              final isAbnormal = status == 'Abnormal';
              final bgColor = isAbnormal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
              final statusColor = isAbnormal ? AppColors.danger : AppColors.success;
              
              final testCount = result.testCount;

              return _buildResultItem(dateStr, '$testCount tests included', status, bgColor, statusColor);
            }),
        ],
      ),
    );
  }

  Widget _buildResultItem(String date, String tests, String status, Color bgColor, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(tests, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsCard(List<LabReport> recentResults) {
    String tipText = 'Upload your lab reports to receive personalized health tips.';
    if (recentResults.isNotEmpty) {
      final latest = recentResults.first;
      final abnormal = latest.testResults?.where((t) => t.status.toLowerCase() != 'normal').toList() ?? [];
      if (abnormal.isNotEmpty) {
        tipText = 'Focus on optimizing your ${abnormal.first.name} levels. Consult the Optimization tab for personalized recipes.';
      } else {
        tipText = 'Your recent results look great! Continue maintaining your current lifestyle and hydration.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 12),
              Text(
                'Health Tip',
                style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tipText,
            style: const TextStyle(color: Color(0xFF92400E), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildTaskItem('Follow-up Lab', 'In 2 months', true),
          _buildTaskItem('Dr. Review', 'Jan 20, 2026', false),
          _buildTaskItem('Prescription Renewal', 'Feb 05, 2026', false),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String deadline, bool isUrgent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.error_outline : Icons.calendar_today_outlined,
            size: 16,
            color: isUrgent ? AppColors.danger : AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(deadline, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
