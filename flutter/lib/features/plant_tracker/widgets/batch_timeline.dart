import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/plant_batch.dart';

class BatchTimeline extends StatelessWidget {
  const BatchTimeline({
    super.key,
    required this.events,
  });

  final List<BatchTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'No timeline events yet.',
        style: AppTextStyles.bodyMedium,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineTile(
            event: events[i],
            isLast: i == events.length - 1,
            index: i,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.index,
  });

  final BatchTimelineEvent event;
  final bool isLast;
  final int index;

  Color get _accent => switch (event.type) {
        BatchTimelineType.planted => AppColors.emerald,
        BatchTimelineType.scan => AppColors.indigo,
        BatchTimelineType.reminder => AppColors.primary,
      };

  IconData get _icon => switch (event.type) {
        BatchTimelineType.planted => Icons.eco_outlined,
        BatchTimelineType.scan => Icons.document_scanner_outlined,
        BatchTimelineType.reminder => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(event.occurredAt);
    final isFuture = event.occurredAt.isAfter(DateTime.now());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(_icon, size: 16, color: _accent),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(event.typeLabel, style: AppTextStyles.titleMedium),
                      if (isFuture) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Upcoming',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(dateLabel, style: AppTextStyles.labelSmall),
                  if (event.title != null) ...[
                    const SizedBox(height: 4),
                    Text(event.title!, style: AppTextStyles.bodySmall),
                  ],
                  if (event.subtitle != null)
                    Text(event.subtitle!, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: (index * 50).ms)
        .slideX(begin: 0.04, end: 0, duration: 280.ms);
  }
}
