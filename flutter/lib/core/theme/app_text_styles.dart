import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography: Outfit for display/headings, Inter for body and labels.
///
/// Both are bundled variable fonts (see pubspec `fonts:`), not fetched at
/// runtime. `google_fonts` downloaded them from fonts.gstatic.com on first use,
/// which threw an unhandled exception and silently fell back to the system
/// typeface on any device that was offline at first launch.
///
/// Because these are variable files, the weight is set on the `wght` axis as
/// well as `fontWeight`: `fontWeight` only picks a file, and there is one file
/// per family.
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle _font(
    String family,
    FontWeight weight, {
    required double size,
    required double height,
    Color? color,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.foreground,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );

  static TextStyle _heading(
    FontWeight weight, {
    required double size,
    required double height,
    double? letterSpacing,
  }) =>
      _font('Outfit', weight,
          size: size, height: height, letterSpacing: letterSpacing);

  static TextStyle _body(
    FontWeight weight, {
    required double size,
    required double height,
    Color? color,
  }) =>
      _font('Inter', weight, size: size, height: height, color: color);

  // --- Display / headings (Outfit) --------------------------------------
  static TextStyle get displayLarge =>
      _heading(FontWeight.w700, size: 32, height: 1.2, letterSpacing: -0.6);

  static TextStyle get displayMedium =>
      _heading(FontWeight.w600, size: 28, height: 1.22, letterSpacing: -0.5);

  static TextStyle get headlineLarge =>
      _heading(FontWeight.w600, size: 24, height: 1.3, letterSpacing: -0.3);

  static TextStyle get headlineMedium =>
      _heading(FontWeight.w600, size: 20, height: 1.3, letterSpacing: -0.2);

  static TextStyle get headlineSmall =>
      _heading(FontWeight.w600, size: 18, height: 1.35);

  // --- Titles (Inter, for denser UI chrome) -----------------------------
  static TextStyle get titleLarge =>
      _body(FontWeight.w600, size: 16, height: 1.4);

  static TextStyle get titleMedium =>
      _body(FontWeight.w600, size: 14, height: 1.4);

  static TextStyle get titleSmall =>
      _body(FontWeight.w600, size: 13, height: 1.4);

  // --- Body -------------------------------------------------------------
  static TextStyle get bodyLarge => _body(
        FontWeight.w400,
        size: 16,
        height: 1.55,
        color: AppColors.foregroundSecondary,
      );

  static TextStyle get bodyMedium => _body(
        FontWeight.w400,
        size: 14,
        height: 1.55,
        color: AppColors.foregroundSecondary,
      );

  /// 12px is the floor for body-adjacent text — nothing smaller carries meaning.
  static TextStyle get bodySmall => _body(
        FontWeight.w400,
        size: 12,
        height: 1.5,
        color: AppColors.muted,
      );

  // --- Labels / metadata ------------------------------------------------
  static TextStyle get labelLarge =>
      _body(FontWeight.w500, size: 14, height: 1.4);

  static TextStyle get labelMedium => _body(
        FontWeight.w500,
        size: 12,
        height: 1.4,
        color: AppColors.foregroundSecondary,
      );

  static TextStyle get labelSmall => _body(
        FontWeight.w500,
        size: 12,
        height: 1.4,
        color: AppColors.muted,
      );

  // --- Aliases ----------------------------------------------------------
  static TextStyle get chipText => labelLarge;
  static TextStyle get buttonText => _body(
        FontWeight.w600,
        size: 15,
        height: 1.4,
        color: AppColors.onPrimary,
      );
}

/// Changing `fontWeight` alone on a variable font does nothing — the weight
/// lives on the `wght` axis. This keeps the two in step.
extension VariableWeight on TextStyle {
  TextStyle withWeight(FontWeight weight) => copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );
}
