import 'package:flutter/material.dart';
import 'app_card.dart';

/// Backward-compatible alias for [AppCard].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

class SolidGlassCard extends GlassCard {
  const SolidGlassCard({
    super.key,
    required super.child,
    super.padding,
    super.margin,
    super.onTap,
  });
}

class AccentGlassCard extends GlassCard {
  const AccentGlassCard({
    super.key,
    required super.child,
    required Color accentColor,
    super.padding,
    super.margin,
    super.onTap,
  });
}
