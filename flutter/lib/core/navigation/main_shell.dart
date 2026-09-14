import 'package:flutter/material.dart';

import '../../screens/history_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/plant_tracker_screen.dart';
import '../../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'app_navigator.dart';

/// Hosts the four primary tabs in an [IndexedStack].
///
/// Tabs used to be separate routes swapped with `pushReplacementNamed`, which
/// rebuilt each screen from scratch on every switch (losing scroll position and
/// re-fetching history) and left the back button with nothing sensible to do.
/// One shell keeps all four alive and makes back mean "leave the app", which is
/// what Android users expect from a bottom-nav root.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  int get index => _index;

  void setTab(int value) {
    if (value == _index || value < 0 || value > 3) return;
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from any tab other than Home returns to Home first, rather than
      // dropping the user out of the app from a deep tab.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setTab(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            HistoryScreen(),
            PlantTrackerScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: PlantDocBottomNav(
          currentIndex: _index,
          onTap: setTab,
          onScanTap: () => AppNavigator.goToScan(context),
        ),
      ),
    );
  }
}
