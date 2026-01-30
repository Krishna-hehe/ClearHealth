import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return widget.child;

    return Stack(
      children: [
        // Base Background
        Container(color: AppColors.midnightBlue),

        // Orb 1: Top Left (Cyan) - Boosted
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              top: -100 + (sin(_controller.value * 2 * pi) * 20),
              left: -100 + (cos(_controller.value * 2 * pi) * 20),
              child: _buildOrb(AppColors.primaryBrand, 500, opacity: 0.25),
            );
          },
        ),

        // Orb 2: Bottom Right (Emerald/Green) - Boosted
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              bottom: -150 - (sin(_controller.value * 2 * pi) * 30),
              right: -50 + (cos(_controller.value * 2 * pi) * 30),
              child: _buildOrb(AppColors.success, 450, opacity: 0.2),
            );
          },
        ),

        // Orb 3: Center-Right (Purple hint) - Boosted
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              right: -100 + (sin(_controller.value * 2 * pi) * 40),
              child: _buildOrb(const Color(0xFF8B5CF6), 350, opacity: 0.15),
            );
          },
        ),

        // Glass Overlay (to smooth everything out further)
        Positioned.fill(
          child: Container(
            color: AppColors.midnightBlue.withValues(alpha: 0.3),
          ),
        ),

        // Main Content
        widget.child,
      ],
    );
  }

  Widget _buildOrb(Color color, double size, {double opacity = 0.3}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
