import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

class PageBackground extends StatelessWidget {
  const PageBackground({
    super.key,
    this.imagePath = AppAssets.pageBg,
    this.overlayOpacity = 0.72,
    this.gradientOverlay,
  });

  final String imagePath;
  final double overlayOpacity;
  final Gradient? gradientOverlay;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _AssetBackgroundImage(imagePath: imagePath),
          if (gradientOverlay != null)
            DecoratedBox(decoration: BoxDecoration(gradient: gradientOverlay))
          else
            ColoredBox(
              color: AppColors.background.withValues(alpha: overlayOpacity),
            ),
        ],
      ),
    );
  }
}

class HeroBackground extends StatelessWidget {
  const HeroBackground({
    super.key,
    this.imagePath = AppAssets.pageBg,
    this.height,
    this.fullScreen = false,
    this.imageAlignment = const Alignment(0, -0.35),
    this.gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Color(0x66000000),
        Color(0xCC0A1410),
        AppColors.background,
      ],
      stops: [0.0, 0.4, 0.72, 1.0],
    ),
  });

  final String imagePath;
  final double? height;
  final bool fullScreen;
  final Alignment imageAlignment;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? MediaQuery.sizeOf(context).height * 0.38;
    final imageStack = Stack(
      fit: StackFit.expand,
      children: [
        _AssetBackgroundImage(
          imagePath: imagePath,
          alignment: imageAlignment,
          fallback: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A4D2E), AppColors.background],
            ),
          ),
        ),
        DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      ],
    );

    if (fullScreen) return Positioned.fill(child: imageStack);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: resolvedHeight,
      child: imageStack,
    );
  }
}

class _AssetBackgroundImage extends StatelessWidget {
  const _AssetBackgroundImage({
    required this.imagePath,
    this.alignment = Alignment.center,
    this.fallback,
  });

  final String imagePath;
  final Alignment alignment;
  final BoxDecoration? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => fallback != null
          ? DecoratedBox(decoration: fallback!)
          : const ColoredBox(color: AppColors.background),
    );
  }
}
