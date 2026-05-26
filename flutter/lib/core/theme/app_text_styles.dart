import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// PlantDoc Typography System
class AppTextStyles {
  AppTextStyles._();

  // Base font family
  static TextStyle get _baseStyle => GoogleFonts.inter();

  // Display - Large welcome text
  static TextStyle get displayLarge => _baseStyle.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.1,
    letterSpacing: -1,
  );

  static TextStyle get displayMedium => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // Headlines
  static TextStyle get headlineLarge => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.3,
  );

  static TextStyle get headlineMedium => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.3,
  );

  static TextStyle get headlineSmall => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  // Titles
  static TextStyle get titleLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  static TextStyle get titleMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  static TextStyle get titleSmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  // Body text
  static TextStyle get bodyLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.foregroundSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.foregroundSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.5,
  );

  // Labels
  static TextStyle get labelLarge => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
    height: 1.4,
  );

  static TextStyle get labelMedium => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
    height: 1.4,
  );

  static TextStyle get labelSmall => _baseStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Special styles
  static TextStyle get statNumber => _baseStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.1,
  );

  static TextStyle get statLabel => _baseStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.3,
  );

  static TextStyle get chipText => _baseStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
    height: 1.2,
  );

  static TextStyle get buttonText => _baseStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryForeground,
    height: 1.2,
  );
}
