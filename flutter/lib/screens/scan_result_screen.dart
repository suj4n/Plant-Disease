import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/navigation/app_navigator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/crop_thumb.dart';
import '../core/widgets/diagnosis_widgets.dart';
import '../data/models/detection_result.dart';

/// The diagnosis. Three genuinely different outcomes share this screen:
/// a disease, a healthy plant, and a photo with no leaf in it.
class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    // Defensive: a direct deep link could land here with nothing to show.
    if (args is! DetectionResult) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'That result is no longer available. Scan a plant to see a new one.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    if (!args.isIdentifiable) {
      return _UnidentifiedResult(result: args);
    }
    return _DiagnosisResult(result: args);
  }
}

// ---------------------------------------------------------------------------
// No leaf found
// ---------------------------------------------------------------------------

/// The model's `Background_without_leaves` class, rendered as a recovery
/// prompt. The raw class name is never shown, and there is no confidence bar —
/// "97% sure there is no leaf" is not useful to anyone.
class _UnidentifiedResult extends StatelessWidget {
  const _UnidentifiedResult({required this.result});

  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.imagePath != null)
                  _ResultImage(path: result.imagePath!, height: 180),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 34,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "We couldn't identify a plant leaf.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Try again with a clear photo of a single leaf against a '
                  'plain background.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _PhotoTips(),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/scan'),
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 19),
                    label: const Text('Scan again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTips extends StatelessWidget {
  const _PhotoTips();

  static const _tips = [
    'Fill the frame with one leaf.',
    'Use daylight or a bright, even light.',
    'Keep the background plain and uncluttered.',
    'Hold steady so the photo stays sharp.',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('For the best result', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final tip in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.foregroundSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disease or healthy
// ---------------------------------------------------------------------------

class _DiagnosisResult extends StatelessWidget {
  const _DiagnosisResult({required this.result});

  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    final healthy = result.isHealthy;
    final accent = healthy ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        // One scroll view for the whole page: the previous fixed flex split
        // overflowed on short screens.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            _HeaderCard(result: result, accent: accent),
            const SizedBox(height: AppSpacing.md),

            if (healthy) ...[
              _HealthyPanel(result: result),
              const SizedBox(height: AppSpacing.lg),
            ] else ...[
              if (result.description.isNotEmpty) ...[
                _Section(
                  title: 'Overview',
                  icon: Icons.info_outline_rounded,
                  child: Text(result.description, style: AppTextStyles.bodyMedium),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (result.symptoms.isNotEmpty) ...[
                _Section(
                  title: 'Symptoms',
                  icon: Icons.visibility_outlined,
                  child: _Bullets(items: result.symptoms),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (result.treatment.isNotEmpty) ...[
                _Section(
                  title: 'Treatment',
                  icon: Icons.healing_outlined,
                  child: _Bullets(items: result.treatment, numbered: true),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (result.prevention.isNotEmpty) ...[
                _Section(
                  title: 'Prevention',
                  icon: Icons.shield_outlined,
                  child: _Bullets(items: result.prevention),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _Section(
                title: 'Risk level',
                icon: Icons.speed_rounded,
                child: RiskLevelBar(level: result.riskLevel),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (result.meaningfulAlternatives.isNotEmpty) ...[
              _AlternativesSection(result: result),
              const SizedBox(height: AppSpacing.md),
            ],

            const _Disclaimer(),
            const SizedBox(height: AppSpacing.md),
            _Actions(result: result),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.result, required this.accent});

  final DetectionResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.imagePath != null)
                _ResultImage(path: result.imagePath!, height: 72, width: 72)
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: AppRadius.card,
                  ),
                  child: Icon(Icons.eco_rounded, color: accent, size: 32),
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.disease,
                      style: AppTextStyles.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.plant.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CropThumb(plantType: result.plant, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              result.plant,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    HealthStatusBadge(status: result.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ConfidenceIndicator(
            percent: result.confidencePercent,
            color: accent,
          ),
        ],
      ),
    );
  }
}

/// Healthy is its own outcome, not a disease that happens to be called
/// "Healthy Tomato".
class _HealthyPanel extends StatelessWidget {
  const _HealthyPanel({required this.result});

  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    final nextScan = DateTime.now().add(const Duration(days: 14));

    return Column(
      children: [
        AppCard(
          fillColor: AppColors.softGreen,
          borderColor: AppColors.softGreen,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 26,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your plant looks healthy', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      result.description.isNotEmpty
                          ? result.description
                          : 'No disease symptoms were detected in this leaf.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.foregroundSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (result.prevention.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Keep it that way',
            icon: Icons.shield_outlined,
            child: _Bullets(items: result.prevention),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: 'Next check',
          icon: Icons.event_outlined,
          child: Text(
            'Scan this plant again around '
            '${nextScan.day}/${nextScan.month}/${nextScan.year} to catch any '
            'change early.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _AlternativesSection extends StatelessWidget {
  const _AlternativesSection({required this.result});

  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Other possible matches',
      icon: Icons.alt_route_rounded,
      child: Column(
        children: [
          Text(
            'The model also considered these. Compare the symptoms before '
            'treating.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final alt in result.meaningfulAlternatives)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alt.disease, style: AppTextStyles.titleSmall),
                        if (alt.plant.isNotEmpty)
                          Text(alt.plant, style: AppTextStyles.labelSmall),
                      ],
                    ),
                  ),
                  Text(
                    '${alt.confidencePercent}%',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      fillColor: AppColors.cardElevated,
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 17, color: AppColors.muted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'This is an AI suggestion based on one photo, not a confirmed '
              'diagnosis. For a valuable crop, confirm with a local '
              'agricultural extension officer before treating.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.result});

  final DetectionResult result;

  String get _shareText {
    final buffer = StringBuffer()
      ..writeln('PlantDoc result')
      ..writeln('${result.disease}${result.plant.isNotEmpty ? ' on ${result.plant}' : ''}')
      ..writeln('${result.confidencePercent}% AI confidence');
    if (result.treatment.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Treatment:');
      for (final t in result.treatment) {
        buffer.writeln('- $t');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _shareText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Result copied to clipboard')),
                );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () =>
                AppNavigator.goToTab(context, AppNavigator.historyTab),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('View history'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, this.numbered = false});

  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (numbered)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.softGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.labelSmall
                          .withWeight(FontWeight.w600)
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, left: 6, right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.mutedForeground,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(items[i], style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.path, required this.height, this.width});

  final String path;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (path.startsWith('http') || !file.existsSync()) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Image.file(
        file,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        // Decode at display size, not full camera resolution.
        cacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
