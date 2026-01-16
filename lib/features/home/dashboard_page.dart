import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../core/supabase_service.dart';
import '../../core/ai_service.dart';
import '../../core/navigation.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  bool _isLoading = true;
  String _firstName = 'User';
  int _conditionsCount = 0;
  int _prescriptionsCount = 0;
  List<Map<String, dynamic>> _recentResults = [];
  String _aiInsight = 'Loading insights...';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    final supabase = SupabaseService();
    try {
      // 1. Fetch Profile for Name & Conditions
      final profile = await supabase.getProfile();
      if (profile != null) {
        // Assuming first_name field exists, otherwise use a fallback or parse email/name
        _firstName = profile['first_name'] ?? 'Krishna'; 
        final conditions = profile['conditions'] as List<dynamic>? ?? [];
        _conditionsCount = conditions.length;
      }

      // 2. Fetch Active Prescriptions
      _prescriptionsCount = await supabase.getActivePrescriptionsCount();

      // 3. Fetch Recent Lab Results (limit 3)
      _recentResults = await supabase.getLabResults(limit: 3);

      // 4. Generate AI Insight if we have results
      if (_recentResults.isNotEmpty) {
        _aiInsight = await AiService.getBatchSummary(_recentResults);
      } else {
        _aiInsight = 'No recent lab results found. Upload a report to get AI insights.';
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      _aiInsight = 'Unable to load insights at this time.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedItem(0, _buildWelcomeHeader()),
          const SizedBox(height: 32),
          _buildAnimatedItem(1, _buildQuickStats()),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildAnimatedItem(2, _buildAiInsightsCard()),
                    const SizedBox(height: 24),
                    _buildAnimatedItem(3, _buildRecentResults()),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildAnimatedItem(4, _buildHealthTipsCard()),
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

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $_firstName',
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

  Widget _buildQuickStats() {
    String lastResultDate = 'N/A';
    String lastResultStatus = 'N/A';
    Color lastResultColor = AppColors.secondary;
    Color lastResultBg = const Color(0xFFF3F4F6);

    if (_recentResults.isNotEmpty) {
      final last = _recentResults.first;
      if (last['date'] != null) {
        final date = DateTime.parse(last['date'].toString());
        lastResultDate = '${date.month}/${date.day}'; // Simple formatting
      }
      lastResultStatus = last['status'] ?? 'Unknown';
      
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
        _buildStatCard('Known Conditions', '$_conditionsCount Active', 'Stable', Icons.favorite_border, const Color(0xFFF0FDF4), AppColors.success),
        const SizedBox(width: 16),
        _buildStatCard('Active Medications', '$_prescriptionsCount Prescriptions', 'On Track', Icons.medication_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
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

  Widget _buildAiInsightsCard() {
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
          Row(
            children: const [
              Icon(FontAwesomeIcons.robot, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'AI Health Insight',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aiInsight,
            style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to full analysis or chat
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

  Widget _buildRecentResults() {
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
          if (_recentResults.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('No results yet.', style: TextStyle(color: AppColors.secondary)),
             )
          else
            ..._recentResults.map((result) {
              final dateStr = result['date']?.toString().split(' ')[0] ?? 'Unknown';
              final status = result['status'] ?? 'Unknown';
              final isAbnormal = status == 'Abnormal';
              final bgColor = isAbnormal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
              final statusColor = isAbnormal ? AppColors.danger : AppColors.success;
              
              // We can display test count or some summary
              final testCount = result['test_count'] ?? 0; // Assuming this field exists or we just show generic text

              return _buildResultItem(dateStr, '$testCount tests included', status, bgColor, statusColor);
            }).toList(),
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

  Widget _buildHealthTipsCard() {
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
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 12),
              Text(
                'Health Tip',
                style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep drinking at least 2.5L of water daily to support your kidney function as seen in your recent creatinine trends.',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 14, height: 1.5),
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
