import 'package:flutter/material.dart';

/// PlantDoc App Color Palette
/// Dark green theme with glassmorphism and vibrant accents
class AppColors {
  AppColors._();

  // Base colors
  static const Color background = Color(0xFF0D1F17);
  static const Color card = Color(0xFF142920);
  static const Color cardElevated = Color(0xFF1A352A);
  static const Color surface = Color(0xFF0F2A1D);

  // Primary accent - Lime green
  static const Color primary = Color(0xFFA3E635);
  static const Color primaryForeground = Color(0xFF0D1F17);

  // Status colors
  static const Color emerald = Color(0xFF34D399); // Healthy
  static const Color coral = Color(0xFFF87171);   // Diseased/Error
  static const Color amber = Color(0xFFFBBF24);   // Warning
  static const Color indigo = Color(0xFF818CF8);  // Info/Scans

  // Text colors
  static const Color foreground = Color(0xFFF1F5F9);
  static const Color foregroundSecondary = Color(0xFFCBD5E1);
  static const Color muted = Color(0xFF64748B);
  static const Color mutedForeground = Color(0xFF94A3B8);

  // Border colors
  static const Color border = Color(0xFF1E3A2F);
  static const Color borderLight = Color(0x1AFFFFFF); // 10% white

  // Glassmorphism
  static const Color glassBackground = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF);     // 10% white
  static const Color glassHighlight = Color(0x0DFFFFFF);  // 5% white

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF84CC16)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [emerald, Color(0xFF10B981)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x80000000),
      Color(0xFF0D1F17),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
