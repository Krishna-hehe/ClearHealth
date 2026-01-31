import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../widgets/glass_card.dart';
import '../../../core/theme.dart';

class RateLimitMonitor extends ConsumerWidget {
  const RateLimitMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limiter = ref.watch(rateLimiterProvider);
    final usage = limiter.getAllUsage();

    if (usage.isEmpty) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No active rate limits in current session.',
            style: TextStyle(color: AppColors.secondary),
          ),
        ),
      );
    }

    return Column(
      children: usage.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(_getIconForAction(entry.key), color: AppColors.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatActionName(entry.key),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                entry.value /
                                10.0, // Assuming a general max of 10 for visual
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              entry.value > 8 ? Colors.red : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForAction(String key) {
    if (key.contains('login')) return Icons.login;
    if (key.contains('chat') || key.contains('ai')) return Icons.auto_awesome;
    if (key.contains('upload')) return Icons.upload_file;
    return Icons.security;
  }

  String _formatActionName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
