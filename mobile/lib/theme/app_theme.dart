import 'package:flutter/material.dart';

class AppColors {
  // Primary Teal Action Color (Clinical Teal, works in both dark and light modes)
  static const primary = Color(0xFF1D9E75);

  // Dark Mode Tokens
  static const darkBackground = Color(0xFF0A1416);
  static const darkSurface = Color(0xFF10201C);
  static const darkSurfaceElevated = Color(0xFF16241F);
  static const darkBorder = Color(0xFF1F332F);
  static const darkTextPrimary = Color(0xFFF5F7FA);
  static const darkTextSecondary = Color(0xFF7FA89D);
  static const darkTextMuted = Color(0xFF5E7A72);

  // Light Mode Tokens
  static const lightBackground = Color(0xFFF4F6F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFEEF3F1);
  static const lightBorder = Color(0xFFE1E6E3);
  static const lightTextPrimary = Color(0xFF16241F);
  static const lightTextSecondary = Color(0xFF5E7A72);
  static const lightTextMuted = Color(0xFF8A9B95);

  // Context-aware dynamic token getters
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : lightSurface;

  static Color surfaceElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceElevated
          : lightSurfaceElevated;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorder
          : lightBorder;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextMuted
          : lightTextMuted;

  // Severity Accent Color Helper
  static Color severityColor(String severity, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'critical_emergency':
        return isDark ? const Color(0xFFF28A8C) : const Color(0xFFB3302F);
      case 'high':
        return isDark ? const Color(0xFFF2AC6E) : const Color(0xFFC97A2E);
      case 'medium':
      case 'stable_urgent':
        return isDark ? const Color(0xFFF2D877) : const Color(0xFFB8941F);
      case 'low':
        return isDark ? const Color(0xFF8FD49C) : const Color(0xFF4F9E5F);
      default:
        return isDark ? const Color(0xFFF2D877) : const Color(0xFFB8941F);
    }
  }

  // Severity Background Tint Helper
  static Color severityBgColor(String severity, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'critical_emergency':
        return isDark ? const Color(0x26F28A8C) : const Color(0xFFFBEAEA);
      case 'high':
        return isDark ? const Color(0x26F2AC6E) : const Color(0xFFFFF3E0);
      case 'medium':
      case 'stable_urgent':
        return isDark ? const Color(0x26F2D877) : const Color(0xFFFFFDE7);
      case 'low':
        return isDark ? const Color(0x268FD49C) : const Color(0xFFE8F5E9);
      default:
        return isDark ? darkSurfaceElevated : lightSurfaceElevated;
    }
  }
}

class AppTheme {
  static const radius = 16.0;

  static ThemeData darkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.darkSurface,
        error: const Color(0xFFF28A8C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.lightSurface,
        error: const Color(0xFFB3302F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}
