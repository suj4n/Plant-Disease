import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'glass_surface.dart';

/// Circular icon affordance. 44dp square so it always clears the touch minimum,
/// and it requires a [semanticLabel] because an icon alone tells a screen
/// reader nothing.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: GlassSurface(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        semanticLabel: semanticLabel,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: iconColor ?? AppColors.foreground),
        ),
      ),
    );
  }
}
