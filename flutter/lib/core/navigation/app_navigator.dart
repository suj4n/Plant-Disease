import 'package:flutter/material.dart';

/// Bottom nav index → route name.
class AppNavigator {
  AppNavigator._();

  static const Map<int, String> tabRoutes = {
    0: '/home',
    1: '/history',
    2: '/tracker',
    3: '/profile',
  };

  static void goToTab(BuildContext context, int index, {int? currentIndex}) {
    if (currentIndex != null && index == currentIndex) return;
    final route = tabRoutes[index];
    if (route != null) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  static void goToScan(BuildContext context) {
    Navigator.pushNamed(context, '/scan');
  }

  static void goToPlantTracker(
    BuildContext context, {
    int? cropIndex,
    String? plantType,
  }) {
    final args = plantType ??
        (cropIndex != null ? cropIndex : null);
    Navigator.pushReplacementNamed(
      context,
      '/tracker',
      arguments: args,
    );
  }
}
