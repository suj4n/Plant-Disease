import 'package:flutter/material.dart';
import '../constants/app_stats.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class CropGridTile extends StatelessWidget {
  const CropGridTile({
    super.key,
    required this.crop,
    this.onTap,
  });

  final SupportedCrop crop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: crop.color.withValues(alpha: 0.22),
              border: Border.all(color: crop.color.withValues(alpha: 0.35)),
              borderRadius: AppRadius.card,
            ),
            child: Icon(crop.icon, color: crop.color, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            crop.name,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
