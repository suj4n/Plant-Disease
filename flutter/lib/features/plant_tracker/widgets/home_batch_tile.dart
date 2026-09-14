import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/crop_thumb.dart';
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
    final urgent = batch.isReminderDueSoon;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CropThumb(plantType: batch.plantType, size: 40),
              const Spacer(),
              if (urgent)
                Icon(
                  Icons.notifications_active,
                  size: 18,
                  color: batch.isReminderDueToday
                      ? AppColors.warning
                      : AppColors.primaryDark,
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
              color: urgent ? AppColors.primaryDark : AppColors.mutedForeground,
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
              color: AppColors.softGreen,
              borderRadius: AppRadius.card,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add plant',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
