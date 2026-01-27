import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/services/trend_analysis_service.dart';

class MarkerStatCard extends StatelessWidget {
  final MarkerStats stats;

  const MarkerStatCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isIncreasing = stats.trendDirection == 'Increasing';
    final bool isDecreasing = stats.trendDirection == 'Decreasing';
    
    // Choose color based on logic: 
    // Generally Increasing is blue, Decreasing is orange/grey (neutral)
    // We already moved to neutral colors in comparison pages
    final Color trendColor = isIncreasing 
        ? Colors.blue.shade600 
        : (isDecreasing ? Colors.orange.shade700 : Colors.grey.shade600);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trendColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: trendColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.testName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                stats.currentValue.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                stats.unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isIncreasing 
                    ? Icons.trending_up 
                    : (isDecreasing ? Icons.trending_down : Icons.trending_flat),
                size: 16,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${stats.percentageChange > 0 ? '+' : ''}${stats.percentageChange.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildStatRow('Avg', stats.average.toStringAsFixed(1)),
          _buildStatRow('Range', '${stats.min.toStringAsFixed(0)}-${stats.max.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
