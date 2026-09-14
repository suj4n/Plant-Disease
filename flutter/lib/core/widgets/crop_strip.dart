import 'package:flutter/material.dart';

import '../constants/app_stats.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'crop_thumb.dart';

/// The four crops PlantDoc can diagnose, shown as photographs.
///
/// This is informational, not decoration: "which plants does this work on?" is
/// the first question a new user has, and four pictures answer it faster than
/// a sentence. Used on Welcome and in the plants/scan empty states.
class CropStrip extends StatelessWidget {
  const CropStrip({super.key, this.thumbSize = 56, this.caption});

  final double thumbSize;

  /// Optional line under the row. Omit where the surrounding copy says it.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Supported crops: ${AppStats.supportedCrops.join(', ')}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              for (final crop in AppStats.crops)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: crop == AppStats.crops.last ? 0 : AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        CropThumb(plantType: crop.name, size: thumbSize),
                        const SizedBox(height: 6),
                        // scaleDown, not ellipsis: "Strawberry" is wider than a
                        // quarter of a 360dp screen, and a truncated crop name
                        // is worse than a slightly smaller one.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            crop.name,
                            maxLines: 1,
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
