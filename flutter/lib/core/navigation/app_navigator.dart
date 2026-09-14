import 'package:flutter/material.dart';
import 'main_shell.dart';

/// Navigation helpers.
///
/// Tab switching happens inside [MainShell] (an IndexedStack), not by pushing
/// routes, so tab state survives and the back button stays predictable.
class AppNavigator {
  AppNavigator._();

  static const int homeTab = 0;
  static const int historyTab = 1;
  static const int plantsTab = 2;
  static const int profileTab = 3;

  static void goToTab(BuildContext context, int index, {int? currentIndex}) {
    final shell = MainShell.of(context);
    if (shell != null) {
      shell.setTab(index);
      return;
    }
    // Called from a pushed screen (e.g. scan result): pop back to the shell
    // and open the requested tab there.
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainShell.of(context)?.setTab(index);
  }

  static Future<void> goToScan(BuildContext context) async {
    await Navigator.pushNamed(context, '/scan');
  }

  static void goToPlantTracker(
    BuildContext context, {
    int? cropIndex,
    String? plantType,
  }) {
    goToTab(context, plantsTab);
  }
}
