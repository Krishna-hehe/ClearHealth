import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- Palette ---
  static const Color midnightBlue = Color(0xFF0B0E14); // Deepest Midnight
  static const Color glassSurface = Color(
    0xFF161B22,
  ); // Slightly lighter for cards

  static const Color primaryBrand = Color(0xFF00F0FF); // Electric Cyan
  static const Color primaryDark = Color(0xFFF8FAFC); // White-ish for Dark Mode

  static const Color accent = Color(0xFF00F0FF); // Electric Cyan
  static const Color success = Color(0xFF00FF94); // Neon Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFFF2E2E); // Bright Red

  // --- Light Mode ---
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // --- Dark Mode ---
  static const Color darkBg = midnightBlue;
  static const Color darkSurface = glassSurface;
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF2D3748); // Slate 700

  // Legacy aliases
  static const Color primary = primaryBrand;
  static const Color secondary = lightTextSecondary;
  static const Color background = lightBg;
  static const Color sidebarBackground = lightSurface;
  static const Color border = lightBorder;
  static const Color cardBg = lightSurface;
}

class AppTheme {
  static TextTheme _buildTextTheme(
    TextTheme base,
    Color bodyColor,
    Color displayColor,
  ) {
    // Inter for Body text
    final baseTheme = GoogleFonts.interTextTheme(
      base,
    ).apply(bodyColor: bodyColor, displayColor: displayColor);

    // Outfit for Headings (Display, Headline, Title)
    final outfitTheme = GoogleFonts.outfitTextTheme(base);

    return baseTheme.copyWith(
      displayLarge: outfitTheme.displayLarge?.copyWith(color: displayColor),
      displayMedium: outfitTheme.displayMedium?.copyWith(color: displayColor),
      displaySmall: outfitTheme.displaySmall?.copyWith(color: displayColor),
      headlineLarge: outfitTheme.headlineLarge?.copyWith(color: displayColor),
      headlineMedium: outfitTheme.headlineMedium?.copyWith(color: displayColor),
      headlineSmall: outfitTheme.headlineSmall?.copyWith(color: displayColor),
      titleLarge: outfitTheme.titleLarge?.copyWith(
        color: displayColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBrand,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBrand,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.danger,
        onPrimary: Colors.black,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
      textTheme: _buildTextTheme(
        ThemeData.light().textTheme,
        AppColors.lightTextPrimary,
        AppColors.lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerColor: AppColors.lightBorder,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBrand,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBrand,
        secondary: AppColors.accent,
        surface: Colors.transparent, // Important for glassmorphism
        error: AppColors.danger,
        onPrimary: Colors.black,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkBorder,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      textTheme: _buildTextTheme(
        ThemeData.dark().textTheme,
        AppColors.darkTextPrimary,
        AppColors.darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface.withValues(alpha: 0.5), // Base falllback
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerColor: AppColors.darkBorder,
    );
  }
}
