import 'package:flutter/material.dart';

import '../../../core/constants/app_stats.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/plant_batch.dart';

/// Compact square tile for the home screen batch grid.
class HomeBatchTile extends StatelessWidget {
  const HomeBatchTile({
    super.key,
    required this.batch,
    required this.onTap,
  });

  final PlantBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final crop = AppStats.cropByName(batch.plantType);
    final urgent = batch.isReminderDueSoon;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: crop.color.withValues(alpha: 0.22),
                  border: Border.all(color: crop.color.withValues(alpha: 0.35)),
                  borderRadius: AppRadius.card,
                ),
                child: Icon(crop.icon, color: crop.color, size: 20),
              ),
              const Spacer(),
              if (urgent)
                Icon(
                  Icons.notifications_active,
                  size: 18,
                  color: batch.isReminderDueToday
                      ? AppColors.amber
                      : AppColors.primary,
                ),
            ],
          ),
          const Spacer(),
          Text(
            batch.name,
            style: AppTextStyles.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            batch.plantType,
            style: AppTextStyles.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${batch.daysSincePlanted}d growing',
            style: AppTextStyles.labelSmall,
          ),
          Text(
            batch.nextReminderSummary,
            style: AppTextStyles.labelSmall.copyWith(
              color: urgent ? AppColors.primary : AppColors.mutedForeground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Placeholder tile to add another plant batch.
class HomeAddBatchTile extends StatelessWidget {
  const HomeAddBatchTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add batch',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
