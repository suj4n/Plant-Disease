import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

/// One past diagnosis: thumbnail, disease, plant, confidence, when.
class ScanActivityTile extends StatelessWidget {
  const ScanActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.confidence,
    required this.isHealthy,
    this.plant,
    this.imagePath,
    this.isIdentifiable = true,
    this.onTap,
  });

  final String title;

  /// Relative time, e.g. "2 hours ago".
  final String subtitle;

  /// Whole percent, 0-100.
  final int confidence;
  final bool isHealthy;
  final String? plant;
  final String? imagePath;
  final bool isIdentifiable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = !isIdentifiable
        ? AppColors.muted
        : (isHealthy ? AppColors.success : AppColors.error);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      semanticLabel: '$title, $subtitle, $confidence percent confidence',
      child: Row(
        children: [
          _Thumbnail(imagePath: imagePath, accent: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (plant != null && plant!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    plant!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (isIdentifiable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$confidence%',
                  style: AppTextStyles.titleMedium.copyWith(color: accent),
                ),
                Text('confidence', style: AppTextStyles.labelSmall),
              ],
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath, required this.accent});

  final String? imagePath;
  final Color accent;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final radius = BorderRadius.circular(AppRadius.md);

    if (path != null && path.isNotEmpty && !path.startsWith('http')) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            // Decode at display size rather than full camera resolution.
            cacheWidth: (_size * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        );
      }
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(Icons.eco_rounded, color: accent, size: 24),
    );
  }
}
