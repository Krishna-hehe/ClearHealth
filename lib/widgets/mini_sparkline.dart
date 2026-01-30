import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final Color? color;

  const MiniSparkline({
    super.key,
    required this.data,
    this.width = 60,
    this.height = 30,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return SizedBox(width: width, height: height);
    }

    // Determine trend color if not provided
    final trendColor = color ?? _getTrendColor(data);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: trendColor),
      ),
    );
  }

  Color _getTrendColor(List<double> data) {
    final start = data.first;
    final end = data.last;
    if (end > start) return AppColors.success;
    if (end < start) return AppColors.danger;
    return AppColors.secondary;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal;

    // Normalize and scale points
    final widthStep = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      // Invert Y because canvas Y starts at top
      // Handle zero range edge case
      final normalizedY = range == 0 ? 0.5 : (data[i] - minVal) / range;

      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Curve fitting for smoother lines
        final prevX = (i - 1) * widthStep;
        final prevNormalizedY = range == 0
            ? 0.5
            : (data[i - 1] - minVal) / range;
        final prevY = size.height - (prevNormalizedY * size.height);

        final controlX1 = prevX + widthStep / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + widthStep / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    // Add a glow effect
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);

    // Draw endpoint dot
    final lastX = size.width;
    final lastNormalizedY = range == 0 ? 0.5 : (data.last - minVal) / range;
    final lastY = size.height - (lastNormalizedY * size.height);

    canvas.drawCircle(
      Offset(lastX, lastY),
      3.0,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
