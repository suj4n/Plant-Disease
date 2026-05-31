import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_stats.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/plant_batch.dart';

class PlantBatchCard extends StatelessWidget {
  const PlantBatchCard({
    super.key,
    required this.batch,
    required this.onTap,
    this.animationIndex = 0,
  });

  final PlantBatch batch;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final crop = AppStats.cropByName(batch.plantType);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: crop.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(crop.icon, color: crop.color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.name, style: AppTextStyles.titleLarge),
                const SizedBox(height: 6),
                Text(
                  batch.plantType,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Planted ${batch.plantedDateLabel}',
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'Next reminder ${batch.nextReminderLabel}',
                  accent: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 320.ms,
          delay: (animationIndex * 60).ms,
        )
        .slideY(begin: 0.06, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: accent ? AppColors.primary : AppColors.muted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: accent ? AppColors.primary : AppColors.mutedForeground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
