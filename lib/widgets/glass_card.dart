import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? tintColor;

  const GlassCard({
    super.key,
    required this.child,
    this.opacity = 0.05,
    this.blur = 10.0,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    // Check for light/dark mode to adjust border/tint defaults
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode, we want a very subtle white tint.
    // In light mode, for standard cards (no explicit tint), we want frosted white.
    final effectiveTintColor = tintColor ?? Colors.white;

    // Adjust defaults based on theme
    double effectiveOpacity = opacity;
    Color borderColor = Colors.white.withValues(alpha: isDark ? 0.15 : 0.5);

    if (!isDark) {
      // Light Mode Tweaks
      // 1. If this is a 'standard' glass card (no custom tint, default opacity)
      //    Boost it to be a visible "Frosted Glass" surface (White 0.7)
      if (tintColor == null && opacity == 0.05) {
        effectiveOpacity = 0.7;
      }

      // 2. Borders need to be darker to be seen on light backgrounds
      borderColor = const Color(0xFFCBD5E1); // Slate 300
    }

    Widget content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Gradient for "Sheen" effect
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveTintColor.withValues(alpha: effectiveOpacity + 0.1),
            effectiveTintColor.withValues(alpha: effectiveOpacity),
          ],
        ),
        borderRadius: BorderRadius.circular(24), // Softer corners
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          // Subtle drop shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );

    // Apply Blur
    content = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent, // Improved touch area
        child: content,
      );
    }

    return content;
  }
}
