import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'glass_surface.dart';

/// Standard content card: white, generously rounded, hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.fillColor,
    this.borderColor,
    this.borderRadius = AppRadius.lg,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      fillColor: fillColor,
      borderColor: borderColor,
      borderRadius: borderRadius,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}
