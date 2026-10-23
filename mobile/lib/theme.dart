import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

export 'theme/app_theme.dart';

class SernColors {
  // Primary Action Color (Clinical Teal)
  static const primary = AppColors.primary;

  // Dark Surface System
  static const darkBg = AppColors.darkBackground;
  static const darkSurface = AppColors.darkSurface;
  static const darkCard = AppColors.darkSurfaceElevated;
  static const darkBorder = AppColors.darkBorder;

  // Aliases for Backwards Compatibility
  static const bg = darkBg;
  static const surface = darkSurface;
  static const card = darkCard;
  static const border = darkBorder;

  // Text Colors
  static const textPrimary = AppColors.darkTextPrimary;
  static const textSecondary = AppColors.darkTextSecondary;
  static const textMuted = AppColors.darkTextMuted;
}

class SernTheme {
  static const radius = 16.0;
  static ThemeData dark() => AppTheme.darkTheme();
  static ThemeData light() => AppTheme.lightTheme();
}