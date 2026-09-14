import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// How certain the *model* is — never how serious the finding is.
///
/// The bar is always the same neutral green. Colouring it by value implied that
/// a confident result was a bad result, which made a 95%-confident *healthy*
/// scan render in alarm red.
class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({
    super.key,
    required this.percent,
    this.label = 'AI confidence',
    this.color = AppColors.primary,
  });

  /// Whole percent, 0-100.
  final int percent;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);

    return Semantics(
      label: '$label $percent percent',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.labelSmall)),
              Text(
                '$percent%',
                style: AppTextStyles.titleMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.cardElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

enum HealthStatus { healthy, diseased, unidentified }

/// Pill stating the outcome in words. Colour reinforces it but never carries
/// the meaning alone.
class HealthStatusBadge extends StatelessWidget {
  const HealthStatusBadge({super.key, required this.status});

  final HealthStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      HealthStatus.healthy => ('Healthy', AppColors.success, Icons.check_circle_rounded),
      HealthStatus.diseased => ('Diseased', AppColors.error, Icons.warning_amber_rounded),
      HealthStatus.unidentified => ('Unidentified', AppColors.muted, Icons.help_outline_rounded),
    };

    // Tag treatment: flat pastel wash, no border, small caps with wide
    // tracking. The icon keeps the meaning off colour alone.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.withWeight(FontWeight.w600).copyWith(
                  color: color,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}

/// Agronomic severity of the disease, independent of model confidence.
class RiskLevelBar extends StatelessWidget {
  const RiskLevelBar({super.key, required this.level});

  /// 'low' | 'medium' | 'high'
  final String level;

  @override
  Widget build(BuildContext context) {
    final normalized = level.toLowerCase();
    final (position, color, caption) = switch (normalized) {
      'low' => (
          0,
          AppColors.riskLow,
          'Manageable with routine care and monitoring.',
        ),
      'high' => (
          2,
          AppColors.riskHigh,
          'Act quickly — this can spread fast or destroy the crop.',
        ),
      _ => (
          1,
          AppColors.riskMedium,
          'Treat soon to stop it spreading through the planting.',
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final active = i <= position;
            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? color : AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              switch (normalized) {
                'low' => 'Low risk',
                'high' => 'High risk',
                _ => 'Medium risk',
              },
              style: AppTextStyles.titleMedium.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(caption, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
