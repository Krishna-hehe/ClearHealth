import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class WellnessGauge extends StatelessWidget {
  final double score; // 0 to 100
  final double size;

  const WellnessGauge({super.key, required this.score, this.size = 200});

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.cyanAccent;
    if (score >= 75) return const Color(0xFF00FF94); // Neon Green
    return Colors.amberAccent;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getScoreColor(score);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(score / 100, primaryColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wellness',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 500),
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.6),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(score.toStringAsFixed(0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _GaugePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background Arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75, // Start at 135 degrees
      pi * 1.5, // Sweep 270 degrees
      false,
      bgPaint,
    );

    // Gradient Progress Arc with Dynamic Color
    final gradient = SweepGradient(
      startAngle: pi * 0.75,
      endAngle: pi * 0.75 + (pi * 1.5),
      tileMode: TileMode.repeated,
      colors: [
        color.withValues(alpha: 0.5), // Start slightly faded
        color, // End at full intensity
      ],
      stops: const [0.0, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.solid,
        6,
      ); // Enhanced neon glow

    // Draw Main Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
