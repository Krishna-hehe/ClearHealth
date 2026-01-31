import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'widgets/security_score_gauge.dart';
import 'widgets/rate_limit_monitor.dart';
import 'widgets/rls_status_card.dart';
import 'widgets/recent_security_events.dart';

class SecurityDashboardPage extends ConsumerWidget {
  const SecurityDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Security Monitoring'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SecurityScoreGauge(),
              const SizedBox(height: 24),
              const RlsStatusCard(),
              const SizedBox(height: 24),
              const Text(
                'Rate Limiting',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              const RateLimitMonitor(),
              const SizedBox(height: 24),
              const Text(
                'Recent Security Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              const RecentSecurityEvents(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
