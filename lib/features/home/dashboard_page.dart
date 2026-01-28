import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/navigation.dart';
import '../../widgets/smart_insight_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create 10 staggered animations (with extra buffer for safety)
    _animations = List.generate(10, (index) {
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
    final labResultsAsync = ref.watch(labResultsProvider);

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
            return labResultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (allResults) {
                final firstName = profile?['first_name'] ?? 'User';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedItem(0, _buildWelcomeHeader(firstName)),
                      const SizedBox(height: 32),
                      // New Lab Stats Row
                      _buildAnimatedItem(1, _buildLabStats(allResults)),
                      const SizedBox(height: 16),

                      // Existing Stats (Conditions/Meds) - Optional, but sticking to user request primarily
                      // _buildAnimatedItem(1, _buildQuickStats(recentResults, conditions.length, pCount)), // Keeping if needed or merging

                      // Let's create a combined stats section or just add the new ones.
                      // User said: "in dashboard also add total number of lab reports,no of need attention and Percenatge of normal results"
                      // I will add a row for these.
                      const SizedBox(height: 24),
                      // Need Attention Box
                      if (allResults.any((r) => r.abnormalCount > 0))
                        _buildAnimatedItem(
                          2,
                          _buildNeedAttentionBox(allResults),
                        ),

                      const SizedBox(height: 32),
                      // Smart AI Forecast
                      _buildAnimatedItem(3, const SmartInsightCard()),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildAnimatedItem(
                                  3,
                                  _buildAiInsightsCard(recentResults),
                                ),
                                const SizedBox(height: 24),
                                _buildAnimatedItem(
                                  4,
                                  _buildRecentResults(recentResults),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAnimatedItem(
                                  5,
                                  _buildHealthTipsCard(recentResults),
                                ),
                                // Upcoming Tasks removed
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Welcome back, $firstName',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            // const StreakFlame(), // Removed as per request
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Here is what is happening with your health today.',
          style: TextStyle(fontSize: 16, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    List<LabReport> recentResults,
    int conditionsCount,
    int prescriptionsCount,
  ) {
    String lastResultDate = 'No Data';
    String lastResultStatus = '-';
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
        _buildStatCard(
          'Last Lab Result',
          lastResultDate,
          lastResultStatus,
          Icons.description_outlined,
          lastResultBg,
          lastResultColor,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Known Conditions',
          '$conditionsCount Active',
          conditionsCount > 0 ? 'Managed' : '-',
          Icons.favorite_border,
          const Color(0xFFF0FDF4),
          AppColors.success,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Active Medications',
          '$prescriptionsCount Prescriptions',
          prescriptionsCount > 0 ? 'Active' : '-',
          Icons.medication_outlined,
          const Color(0xFFEFF6FF),
          const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String status,
    IconData icon,
    Color bgColor,
    Color statusColor,
  ) {
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
                if (status !=
                    '-') // Only show status badge if there is a status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightsCard(List<LabReport> recentResults) {
    // ... (existing implementation)
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              insightAsync.when(
                data: (insight) => Text(
                  insight,
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).toInt()),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, s) => Text(
                  'Failed to load insight: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(navigationProvider.notifier).state =
                      NavItem.healthChat;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Full Analysis',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
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
              const Text(
                'Recent Lab Results',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () => ref.read(navigationProvider.notifier).state =
                    NavItem.labResults,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No results yet.',
                style: TextStyle(color: AppColors.secondary),
              ),
            )
          else
            ...recentResults.map((result) {
              final dateStr = DateFormat('MMM d, yyyy').format(result.date);
              final status = result.status;
              final isAbnormal = status == 'Abnormal';
              final bgColor = isAbnormal
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF0FDF4);
              final statusColor = isAbnormal
                  ? AppColors.danger
                  : AppColors.success;

              final testCount = result.testCount;

              return _buildResultItem(
                dateStr,
                '$testCount tests included',
                status,
                bgColor,
                statusColor,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHealthTipsCard(List<LabReport> recentResults) {
    String tipText =
        'Upload your lab reports to receive personalized health tips.';
    if (recentResults.isNotEmpty) {
      final latest = recentResults.first;
      final abnormal =
          latest.testResults
              ?.where((t) => t.status.toLowerCase() != 'normal')
              .toList() ??
          [];
      if (abnormal.isNotEmpty) {
        tipText =
            'Focus on optimizing your ${abnormal.first.name} levels. Consult the Optimization tab for personalized recipes.';
      } else {
        tipText =
            'Your recent results look great! Continue maintaining your current lifestyle and hydration.';
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipBg = isDark
        ? const Color(0xFF451A03).withOpacity(0.3)
        : const Color(0xFFFFFBEB);
    final tipBorder = isDark
        ? const Color(0xFF78350F).withOpacity(0.5)
        : const Color(0xFFFEF3C7);
    final tipTitleColor = isDark
        ? const Color(0xFFFCD34D)
        : const Color(0xFF92400E); // Amber-300 vs Amber-900
    final tipTextColor = isDark
        ? const Color(0xFFFDE68A)
        : const Color(0xFF92400E); // Amber-200 vs Amber-900

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Health Tip',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: tipTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tipText,
            style: TextStyle(color: tipTextColor, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLabStats(List<LabReport> results) {
    int totalReports = results.length;
    // Calculate total abnormal tests across all reports
    int totalAbnormalTests = results.fold(0, (sum, r) => sum + r.abnormalCount);
    // Count reports that have at least one abnormal result
    int reportsNeedingAttention = results
        .where((r) => r.abnormalCount > 0)
        .length;

    int totalTests = results.fold(0, (sum, r) => sum + r.testCount);
    // Calculate percentage based on tests, not reports
    double normalPct = totalTests > 0
        ? ((totalTests - totalAbnormalTests) / totalTests * 100)
        : 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        List<Widget> cards = [
          _buildStatCard(
            'Total Lab Reports',
            '$totalReports',
            'Reports',
            Icons.folder_open_outlined,
            const Color(0xFFEFF6FF),
            const Color(0xFF3B82F6),
          ),
          SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
          _buildStatCard(
            'Need Attention',
            '$totalAbnormalTests',
            'Abnormal Results',
            Icons.warning_amber_rounded,
            const Color(0xFFFEF2F2),
            AppColors.danger,
          ),
          SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
          _buildStatCard(
            'Normal Results',
            '${normalPct.toStringAsFixed(1)}%',
            'Percentage',
            Icons.check_circle_outline,
            const Color(0xFFF0FDF4),
            AppColors.success,
          ),
        ];

        if (isMobile) {
          return Column(children: cards);
        } else {
          return Row(children: cards);
        }
      },
    );
  }

  Widget _buildNeedAttentionBox(List<LabReport> results) {
    // Flatten all test results that are abnormal
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

    // Sort by date (most recent first)
    abnormalTests.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    // Take top 5
    final displayTests = abnormalTests.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Need Attention',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
              const Spacer(),
              Text(
                '${abnormalTests.length} Abnormal Results',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayTests.isEmpty)
            const Text(
              'No detailed abnormal results found in loaded reports.',
              style: TextStyle(color: AppColors.secondary),
            )
          else
            ...displayTests.map((item) {
              final test = item['test'] as TestResult;
              final date = item['date'] as DateTime;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${test.result} ${test.unit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                        Text(
                          test.reference,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          if (abnormalTests.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).state = "Abnormal";
                    ref.read(navigationProvider.notifier).state =
                        NavItem.labResults;
                  },
                  child: const Text('View All Abnormal Results'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    String date,
    String tests,
    String status,
    Color bgColor,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  tests,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
