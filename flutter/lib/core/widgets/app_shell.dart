import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';
import '../theme/app_spacing.dart';
import 'bottom_nav.dart';

/// Tab shell: scrollable body + optional bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.navIndex,
    this.appBar,
    this.background,
    this.bottomPadding = 88,
  });

  final Widget body;
  final int navIndex;
  final PreferredSizeWidget? appBar;
  final Widget? background;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: background != null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null) background!,
          body,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PlantDocBottomNav(
              currentIndex: navIndex,
              onTap: (i) => AppNavigator.goToTab(context, i, currentIndex: navIndex),
              onScanTap: () => AppNavigator.goToScan(context),
            ),
          ),
        ],
      ),
    );
  }
}

class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.children,
    this.bottomPadding = 88,
  });

  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
