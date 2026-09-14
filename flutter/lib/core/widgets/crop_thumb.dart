import 'package:flutter/material.dart';

import '../constants/app_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Rounded photograph of a crop.
///
/// Replaces the tinted-icon-in-a-coloured-box that three screens each built
/// their own version of. The photo is the only saturated colour in the card,
/// which is what lets the surrounding chrome stay neutral.
class CropThumb extends StatelessWidget {
  const CropThumb({
    super.key,
    required this.plantType,
    this.size = 44,
    this.radius,
  });

  final String plantType;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final crop = AppStats.cropByName(plantType);
    final borderRadius = BorderRadius.circular(radius ?? AppRadius.sm);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        crop.image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Decode at display size — the source files are ~1000px square.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.eco_outlined,
            size: size * 0.5,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}
