import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Reusable full-screen background with image + readability overlay.
class PageBackground extends StatelessWidget {
  final String imagePath;
  final double overlayOpacity;

  const PageBackground({
    super.key,
    this.imagePath = AppAssets.bg,
    this.overlayOpacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: AppColors.background);
            },
          ),
          Container(
            color: AppColors.background.withValues(alpha: overlayOpacity),
          ),
        ],
      ),
    );
  }
}
