import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// The app's base surface: flat fill, hairline border, soft shadow.
///
/// This used to wrap every card in a `BackdropFilter`. On a light botanical
/// ground the blur reads as muddy rather than frosted, and it cost one render
/// layer per list row. The class name and constructor are unchanged so the ~30
/// existing call sites did not have to move.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.fillColor,
    this.borderColor,
    this.shadows,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor ?? AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadows ?? AppShadows.soft,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: fillColor ?? AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: borderColor ?? AppColors.border),
            boxShadow: shadows ?? AppShadows.soft,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: AppColors.softGreen.withValues(alpha: 0.5),
            highlightColor: AppColors.softGreen.withValues(alpha: 0.3),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      );
    }

    if (semanticLabel != null) {
      content = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
