import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// The app's base surface: flat white fill, hairline border, soft shadow.
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

  /// Defaults to [AppSpacing.md] on every side.
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final decoration = BoxDecoration(
      color: fillColor ?? AppColors.surface,
      borderRadius: radius,
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: AppShadows.soft,
    );
    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    Widget content = onTap == null
        ? DecoratedBox(decoration: decoration, child: inner)
        : Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: decoration,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: AppColors.softGreen.withValues(alpha: 0.5),
                highlightColor: AppColors.softGreen.withValues(alpha: 0.3),
                child: inner,
              ),
            ),
          );

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
