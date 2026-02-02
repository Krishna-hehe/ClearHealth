import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/providers/dashboard_providers.dart';
import '../../core/providers.dart';
import '../../core/navigation.dart';
import '../../widgets/smart_insight_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_shimmer.dart';
import '../../widgets/mini_sparkline.dart';

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
      duration: const Duration(milliseconds: 1500),
    );

    // Create staggered animations
    _animations = List.generate(10, (index) {
      double start = index * 0.05;
      double end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final welcomeName = ref.watch(dashboardWelcomeNameProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final recentResultsAsync = ref.watch(recentLabResultsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedItem(0, _buildWelcomeHeader(welcomeName, stats)),
          const SizedBox(height: 32),
          _buildAnimatedItem(1, _buildLabStats(stats)),
          const SizedBox(height: 32),

          if (stats.reportsNeedingAttention > 0)
            _buildAnimatedItem(2, _buildNeedAttentionBox(stats.abnormalTests)),

          const SizedBox(height: 32),
          _buildAnimatedItem(3, const SmartInsightCard()),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 850;

              // Extract and categorize tests from reports
              final categorizedWidgets = recentResultsAsync.maybeWhen(
                data: (reports) => _buildCategorizedLabResults(reports),
                orElse: () => const SizedBox.shrink(),
              );

              final leftColumn = Column(
                children: [
                  recentResultsAsync.maybeWhen(
                    data: (recent) => _buildAnimatedItem(
                      3,
                      GlassShimmer(child: _buildAiInsightsCard(recent)),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  // New Categorized Results
                  _buildAnimatedItem(4, categorizedWidgets),
                ],
              );

              final rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildAnimatedItem(5, _buildHealthTipsCard())],
              );

              if (isMobile) {
                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 24),
                    rightColumn,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: leftColumn),
                    const SizedBox(width: 24),
                    Expanded(child: rightColumn),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedLabResults(List<LabReport> reports) {
    // 1. Flatten all tests from all reports
    final allTests = <TestResult>[];
    for (var report in reports) {
      if (report.testResults != null) {
        allTests.addAll(report.testResults!);
      }
    }

    if (allTests.isEmpty) return const SizedBox.shrink();

    // 2. Map to categories
    final Map<String, List<TestResult>> categories = {
      'Metabolic Health': [],
      'Blood Count': [],
      'Hormones': [],
      'Other Indicators': [],
    };

    for (var test in allTests) {
      final name = test.name.toLowerCase();
      if (name.contains('cholesterol') ||
          name.contains('glucose') ||
          name.contains('hba1c') ||
          name.contains('lipid') ||
          name.contains('triglyceride')) {
        categories['Metabolic Health']!.add(test);
      } else if (name.contains('hemoglobin') ||
          name.contains('wbc') ||
          name.contains('rbc') ||
          name.contains('platelet') ||
          name.contains('hematocrit')) {
        categories['Blood Count']!.add(test);
      } else if (name.contains('tsh') ||
          name.contains('t3') ||
          name.contains('t4') ||
          name.contains('thyroid')) {
        categories['Hormones']!.add(test);
      } else {
        categories['Other Indicators']!.add(test);
      }
    }

    // 3. Build Widgets
    return Column(
      children: categories.entries.where((e) => e.value.isNotEmpty).map((
        entry,
      ) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(entry.key),
                      color: AppColors.primaryBrand,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...entry.value
                    .take(5)
                    .map(
                      (test) => _buildEnhancedTestRow(test),
                    ), // Limit to 5 per category
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Metabolic Health':
        return FontAwesomeIcons.fire;
      case 'Blood Count':
        return FontAwesomeIcons.droplet;
      case 'Hormones':
        return FontAwesomeIcons.dna;
      default:
        return FontAwesomeIcons.notesMedical;
    }
  }

  Widget _buildEnhancedTestRow(TestResult test) {
    final isAbnormal =
        test.status.toLowerCase() == 'abnormal' ||
        test.status.toLowerCase() == 'high' ||
        test.status.toLowerCase() == 'low';
    final statusColor = isAbnormal ? AppColors.danger : AppColors.success;

    // Mock data generation for sparkline based on current result
    // In a real app, this would come from history
    final currentVal =
        double.tryParse(test.result.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final mockTrend = [
      currentVal * (0.9 + (Random().nextDouble() * 0.2)),
      currentVal * (0.9 + (Random().nextDouble() * 0.2)),
      currentVal * (0.9 + (Random().nextDouble() * 0.2)),
      currentVal,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  test.reference,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Clean Value Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${test.result} ${test.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAbnormal
                      ? AppColors.danger
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              if (isAbnormal)
                Text(
                  test.status,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Micro-Insight Sparkline
          MiniSparkline(
            data: mockTrend,
            width: 40,
            height: 20,
            color: statusColor,
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

  Widget _buildWelcomeHeader(String firstName, DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $firstName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your AI Health Dashboard is ready.',
                style: TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
            ],
          ),
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
      child: GlassCard(
        padding: const EdgeInsets.all(20),
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
                if (status != '-')
                  Flexible(
                    child: Container(
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
                        overflow: TextOverflow.ellipsis,
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
    return Consumer(
      builder: (context, ref, child) {
        final insightAsync = ref.watch(dashboardAiInsightProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final contrastColor = isDark ? Colors.white : const Color(0xFF4F46E5);

        return GlassCard(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          tintColor: const Color(0xFF4F46E5),
          opacity: 0.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.robot,
                    color: AppColors.primaryBrand,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Health Insight',
                    style: TextStyle(
                      color: contrastColor,
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF1E1B4B), // Indigo 900 for Light Mode
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBrand,
                  ),
                ),
                error: (e, s) => Text(
                  'Failed to load insight: $e',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(navigationProvider.notifier).state =
                      NavItem.healthChat;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrand,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildHealthTipsCard() {
    final tipsAsync = ref.watch(optimizationTipsProvider);

    return tipsAsync.when(
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (tips) {
        String tipTitle = 'Health Tip';
        String tipText =
            'Upload your lab reports to receive personalized health tips.';
        Color themeColor = const Color(0xFFD97706); // Amber default

        if (tips.isNotEmpty) {
          final firstTip = tips.first;
          final type = firstTip['type']?.toString() ?? 'General';

          if (type == 'Maintenance' || type == 'General') {
            themeColor = AppColors.success;
            tipTitle = 'Wellness Tip';
            tipText = '${firstTip['title']}: ${firstTip['description']}';
          } else {
            themeColor = AppColors.warning;
            tipTitle = 'Optimization Tip';
            tipText = '${firstTip['title']}: ${firstTip['description']}';
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tipTextColor = isDark
            ? themeColor.withRed(255).withGreen(255).withBlue(255)
            : themeColor;

        return GlassCard(
          padding: const EdgeInsets.all(24),
          tintColor: themeColor,
          opacity: isDark ? 0.15 : 0.05,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: themeColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    tipTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tipText,
                style: TextStyle(
                  color: tipTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabStats(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        List<Widget> cards = [
          _buildStatCard(
            'Total Lab Reports',
            '${stats.totalReports}',
            'Reports',
            Icons.folder_open_outlined,
            const Color(0xFFEFF6FF),
            const Color(0xFF3B82F6),
          ),
          SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
          _buildStatCard(
            'Need Attention',
            '${stats.totalAbnormalTests}',
            'Abnormal Results',
            Icons.warning_amber_rounded,
            const Color(0xFFFEF2F2),
            AppColors.danger,
          ),
          SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
          _buildStatCard(
            'Normal Results',
            '${stats.normalPct.toStringAsFixed(1)}%',
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

  Widget _buildNeedAttentionBox(List<Map<String, dynamic>> abnormalTests) {
    final displayTests = abnormalTests.take(5).toList();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      tintColor: AppColors.danger,
      opacity: 0.05,
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
              // Mock trend for abnormal
              final currentVal =
                  double.tryParse(
                    test.result.replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0.0;
              final mockTrend = [
                currentVal * 0.8,
                currentVal * 0.9,
                currentVal,
              ];

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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(item['date']),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${test.result} ${test.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    MiniSparkline(
                      data: mockTrend,
                      width: 30,
                      height: 15,
                      color: AppColors.danger,
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
}
