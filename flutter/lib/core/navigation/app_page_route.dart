import 'package:flutter/material.dart';

/// Shared fade transitions for consistent navigation across PlantDoc.
class AppPageRoute {
  AppPageRoute._();

  static const Duration defaultDuration = Duration(milliseconds: 400);
  static const Duration welcomeDuration = Duration(milliseconds: 500);

  static PageRouteBuilder<T> fade<T extends Object?>(
    Widget page, {
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: duration,
    );
  }

  static void pushReplacementFade(
    BuildContext context,
    Widget page, {
    Duration duration = defaultDuration,
  }) {
    Navigator.of(context).pushReplacement(fade(page, duration: duration));
  }

}
