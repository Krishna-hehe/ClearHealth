import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF1A1A1A);
  static const Color secondary = Color(0xFF6B7280);
  static const Color background = Color(0xFFFCFCFC);
  static const Color sidebarBackground = Colors.white;
  static const Color accent = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBg = Colors.white;
  static const Color greenRange = Color(0xFFE8F5E9);
  static const Color greenText = Color(0xFF2E7D32);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
        primary: Colors.white,
        surface: const Color(0xFF111827).withValues(alpha: 0.6), // Transparent surface
      ),
      scaffoldBackgroundColor: Colors.transparent, // Allow gradient to show through
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F2937).withValues(alpha: 0.5), // Glassmorphic
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
