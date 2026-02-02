import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SecurityScoreGauge extends StatelessWidget {
  final double score;

  const SecurityScoreGauge({super.key, this.score = 85.0});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 15,
                  backgroundColor: color.withAlpha(51),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.toInt()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Text(
                    'SECURITY SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdown(),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric('RLS', '100%'),
        _buildMetric('Auth', '100%'),
        _buildMetric('Rate Limits', '100%'),
        _buildMetric('Validation', '100%'),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.secondary),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
