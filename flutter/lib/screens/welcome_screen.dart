import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/navigation/app_page_route.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'home_screen.dart';

/// Welcome / onboarding — tea plantation background, tappable leaf to enter app.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.welcomeBg,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(color: AppColors.background),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                    AppColors.background.withValues(alpha: 0.92),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  _buildStatsPills(),
                  const SizedBox(height: 24),
                  _buildLocationBadge(),
                  const Spacer(flex: 2),
                  _buildWelcomeText(),
                  const SizedBox(height: 24),
                  _buildFeatureCarousel(),
                  const SizedBox(height: 32),
                  _buildLeafButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPills() {
    const stats = [
      {'value': '95%+', 'label': 'Accuracy'},
      {'value': '38+', 'label': 'Diseases'},
      {'value': '14', 'label': 'Crops'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stats.map((stat) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stat['value']!,
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              Text(
                stat['label']!,
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text('Nepal', style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'WELCOME TO',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.muted,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text('PLANTDOC', style: AppTextStyles.displayLarge.copyWith(letterSpacing: 2)),
        const SizedBox(height: 16),
        Text(
          'Detect plant diseases instantly with\nAI-powered scanning technology',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureCarousel() {
    const features = [
      {'icon': Icons.camera_alt, 'label': 'Instant Scan'},
      {'icon': Icons.psychology, 'label': 'Smart AI'},
      {'icon': Icons.track_changes, 'label': 'Track Health'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: features.map((feature) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(feature['icon'] as IconData, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(feature['label'] as String, style: AppTextStyles.labelMedium),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeafButton(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppPageRoute.pushReplacementFade(
              context,
              const HomeScreen(),
              duration: AppPageRoute.welcomeDuration,
            );
          },
          customBorder: const CircleBorder(),
          child: Ink(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.eco,
              color: AppColors.primaryForeground,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
