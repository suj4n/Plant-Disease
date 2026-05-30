import 'package:flutter/material.dart';

/// Border radius: 10–14.
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;

  static final BorderRadius card = BorderRadius.circular(md);
  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius chip = BorderRadius.circular(lg);
}
