import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/providers/lab_providers.dart';
import '../core/theme.dart';

class SmartInsightCard extends ConsumerWidget {
  const SmartInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(healthPredictionsProvider);

    return predictionsAsync.when(
      data: (predictions) {
        if (predictions.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Health Forecast',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF818CF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF334155), height: 1),
              
              // Horizontal Scroll for multiple insights
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: predictions.map((prediction) => _buildPredictionItem(context, prediction)).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(), // Don't show anything while loading to avoid layout shift, or show skeleton
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildPredictionItem(BuildContext context, Map<String, dynamic> data) {
    final metric = data['metric'] ?? 'Metric';
    final current = data['current_value'] ?? '-';
    final predicted = data['predicted_value'] ?? '-';
    final direction = data['trend_direction'] ?? 'Stable';
    final risk = data['risk_level'] ?? 'Low';
    final insight = data['insight'] ?? '';
    final recommendation = data['recommendation'] ?? '';

    Color trendColor = AppColors.success;
    IconData trendIcon = Icons.trending_flat;
    
    if (direction == 'Increasing') {
      trendIcon = Icons.trending_up;
      trendColor = Colors.orange; // Context-dependent, but neutral for now
    } else if (direction == 'Decreasing') {
      trendIcon = Icons.trending_down;
      trendColor = Colors.blue; 
    }

    Color riskColor = AppColors.success;
    if (risk == 'Medium') riskColor = Colors.orange;
    if (risk == 'High') riskColor = AppColors.danger;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(metric, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: riskColor.withOpacity(0.5)),
                ),
                child: Text(
                  '$risk Risk',
                  style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildValueColumn('Current', current, Colors.white70),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.3), size: 16),
              const SizedBox(width: 12),
              _buildValueColumn('Predicted (3mo)', predicted, Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Trend: $direction',
                style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12,  height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: const Color(0xFF818CF8).withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Icon(Icons.lightbulb_outline, color: Color(0xFF818CF8), size: 12),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     recommendation,
                     style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                   ),
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
