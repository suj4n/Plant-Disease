import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'glass_surface.dart';

class HighlightChip extends StatelessWidget {
  const HighlightChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      fillColor: AppColors.glassFillStrong,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
