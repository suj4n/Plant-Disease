import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A short header photograph with content laid over its lower half.
///
/// Ambient imagery, under deliberate constraints: one per screen, header only,
/// never taller than 150px, never behind an interactive control. Full-bleed
/// hero photos were removed from this app once already for pushing content
/// below the fold — this is the disciplined version.
///
/// The scrim is a gradient, measured rather than guessed. White text needs the
/// *worst* pixel behind it to clear 4.5:1, not the average: on
/// `field_terraces.jpg` a flat 45% scrim leaves the brightest pixel at 2.6:1.
/// Ramping 0.25 -> 0.78 keeps the top of the photograph legible while the text
/// zone at the bottom clears AA with margin.
class PhotoBand extends StatelessWidget {
  const PhotoBand({
    super.key,
    required this.image,
    required this.child,
    this.height = 132,
    this.borderRadius,
  });

  final String image;
  final Widget child;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.card;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative: excluded from the semantics tree, since the overlaid
            // text already says everything a screen reader needs.
            ExcludeSemantics(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                // Decode at band size, not the 1080px source.
                cacheHeight: (height * dpr).round(),
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: AppColors.primaryDark),
              ),
            ),
            const _Scrim(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.foreground.withValues(alpha: 0.25),
            AppColors.foreground.withValues(alpha: 0.52),
            AppColors.foreground.withValues(alpha: 0.78),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
