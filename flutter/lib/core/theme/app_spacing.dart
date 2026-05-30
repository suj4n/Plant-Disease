import 'package:flutter/material.dart';

/// Spacing scale: 8, 12, 16, 24 only.
abstract final class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  static const EdgeInsets screen = EdgeInsets.all(md);
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: md);
}
