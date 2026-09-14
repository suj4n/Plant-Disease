import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Body wrapper for a tab inside [MainShell].
///
/// The shell now owns the Scaffold and the bottom navigation, so this is just
/// a safe-area scroll surface with the right bottom clearance for the floating
/// nav bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.body, this.onRefresh});

  final Widget body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(bottom: false, child: body);
    if (onRefresh == null) return content;
    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

/// Scrolling column with screen padding and clearance for the floating nav.
class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.children,
    this.bottomPadding,
    this.controller,
  });

  final List<Widget> children;

  /// Defaults to the floating nav bar's height plus the device's bottom inset.
  final double? bottomPadding;

  final ScrollController? controller;

  /// Clearance the floating bottom navigation needs on this device.
  static double navClearance(BuildContext context) =>
      AppSpacing.bottomNavClearance + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      // Always scrollable so pull-to-refresh works even on a short screen.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomPadding ?? navClearance(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
