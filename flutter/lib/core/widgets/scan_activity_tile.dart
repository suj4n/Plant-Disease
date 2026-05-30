import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class ScanActivityTile extends StatelessWidget {
  const ScanActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.confidence,
    required this.isHealthy,
  });

  final String title;
  final String subtitle;
  final int confidence;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.success : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              borderRadius: AppRadius.card,
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$confidence%', style: AppTextStyles.titleMedium.copyWith(color: color)),
              Text('confidence', style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
