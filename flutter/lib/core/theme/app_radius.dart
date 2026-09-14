import 'package:flutter/material.dart';

/// Border radii, deliberately crisp.
///
/// These were 12/16/20/28. Large soft corners read as "friendly app"; tight
/// ones read as considered. [pill] is reserved for tags, badges and progress
/// tracks — never for cards or primary buttons.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;

  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius chip = BorderRadius.circular(pill);
  static final BorderRadius hero = BorderRadius.circular(xl);
}
