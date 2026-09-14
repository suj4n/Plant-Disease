import 'package:flutter/material.dart';

/// Spacing scale. The xl/xxl rungs exist so screens can breathe the way the
/// botanical design direction needs; xs..lg are unchanged so no call site moved.
abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const EdgeInsets screen = EdgeInsets.all(md);
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: md);

  /// Clearance for the floating bottom navigation bar.
  static const double bottomNavClearance = 104;
}
