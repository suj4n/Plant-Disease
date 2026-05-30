import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'glass_surface.dart';

/// Glassmorphism card for grouped content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: child,
    );
  }
}
