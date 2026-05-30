import 'package:flutter/material.dart';

/// Dark glass palette — deep green base, lime accent, frosted surfaces.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A1410);
  static const Color surface = Color(0xFF142920);
  static const Color card = Color(0xFF142920);
  static const Color cardElevated = Color(0xFF1A352A);

  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassFillStrong = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  static const Color primary = Color(0xFFA3E635);
  static const Color onPrimary = Color(0xFF0D1F17);

  static const Color foreground = Color(0xFFF1F5F9);
  static const Color foregroundSecondary = Color(0xFFCBD5E1);
  static const Color muted = Color(0xFF64748B);
  static const Color mutedForeground = Color(0xFF94A3B8);

  static const Color border = Color(0xFF1E3A2F);
  static const Color divider = Color(0xFF1A3028);

  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);

  static const Color emerald = Color(0xFF34D399);
  static const Color coral = Color(0xFFF87171);
  static const Color amber = Color(0xFFFBBF24);
  static const Color indigo = Color(0xFF818CF8);

  static const Color primaryForeground = Color(0xFF0D1F17);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF84CC16)],
  );

  static List<BoxShadow> get elevationLow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];
}
