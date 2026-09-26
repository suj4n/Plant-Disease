import 'package:flutter/material.dart';

/// Spacing scale.
abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const EdgeInsets screen = EdgeInsets.all(md);

  /// Clearance for the floating bottom navigation bar.
  static const double bottomNavClearance = 104;
}
