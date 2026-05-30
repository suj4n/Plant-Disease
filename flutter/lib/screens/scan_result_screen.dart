import 'dart:io';

import 'package:flutter/material.dart';

import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/page_background.dart';

/// Displays scan results from API data passed via [ModalRoute] arguments.
class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_saved) {
        _saved = true;
        final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>? ??
            {};
        ScanStorage.save(args);
      }
    });
  }

  static int _normalizeConfidence(dynamic rawConf) {
    if (rawConf == null) return 0;
    if (rawConf is num) {
      final v = rawConf.toDouble();
      return v <= 1.0 ? (v * 100).round() : v.round();
    }
    if (rawConf is String) {
      final asDouble = double.tryParse(rawConf);
      if (asDouble != null) {
        return asDouble <= 1.0 ? (asDouble * 100).round() : asDouble.round();
      }
      return int.tryParse(rawConf) ?? 0;
    }
    return 0;
  }

  static Color _confidenceBarColor(int confidence) {
    if (confidence >= 80) return AppColors.coral;
    if (confidence >= 50) return AppColors.amber;
    return AppColors.emerald;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final disease = args['disease']?.toString() ?? 'Unknown';
    final confidence = _normalizeConfidence(args['confidence']);
    final imagePath = args['imagePath'] as String?;
    final isHealthy = args['isHealthy'] as bool? ??
        (confidence > 70 && disease.toLowerCase().contains('healthy'));
    final recommendations = (args['recommendations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    File? imageFile;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) imageFile = file;
    }

    final primaryCardColor = isHealthy ? AppColors.emerald : AppColors.coral;
    final barColor = _confidenceBarColor(confidence);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const PageBackground(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isHealthy ? AppColors.emerald : AppColors.coral)
                        .withValues(alpha: 0.25),
                    AppColors.background.withValues(alpha: 0.0),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  flex: 4,
                  child: _buildPlantVisualization(imageFile, isHealthy),
                ),
                Expanded(
                  flex: 5,
                  child: _buildBottomPanel(
                    context: context,
                    disease: disease,
                    confidence: confidence,
                    isHealthy: isHealthy,
                    recommendations: recommendations,
                    primaryCardColor: primaryCardColor,
                    barColor: barColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.foreground,
              ),
            ),
          ),
          const Spacer(),
          Text('Scan Result', style: AppTextStyles.headlineSmall),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPlantVisualization(File? imageFile, bool isHealthy) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (imageFile != null)
          ClipOval(
            child: Image.file(
              imageFile,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco,
              color: isHealthy ? AppColors.emerald : AppColors.coral,
              size: 60,
            ),
          ),
        ...List.generate(3, (index) {
          return Container(
            width: 160 + (index * 40),
            height: 160 + (index * 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: 0.1 - (index * 0.03),
                ),
                width: 1,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomPanel({
    required BuildContext context,
    required String disease,
    required int confidence,
    required bool isHealthy,
    required List<String> recommendations,
    required Color primaryCardColor,
    required Color barColor,
  }) {
    final secondCard = recommendations.isNotEmpty
        ? _buildDiseaseCard(
            title: 'TREATMENT',
            percentage: confidence,
            description: recommendations.first.length > 80
                ? '${recommendations.first.substring(0, 80)}...'
                : recommendations.first,
            color: AppColors.amber,
          )
        : _buildDiseaseCard(
            title: 'SCAN AGAIN',
            percentage: 0,
            description: 'Try better lighting\nfor a clearer scan',
            color: AppColors.indigo,
            showProgress: false,
          );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rescan Your Plant',
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDiseaseCard(
                    title: disease.toUpperCase(),
                    percentage: confidence,
                    description: '$confidence% confidence',
                    color: primaryCardColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: secondCard),
              ],
            ),
            const SizedBox(height: 20),
            Text('Confidence Breakdown', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _buildConfidenceBar(
              label: disease,
              value: confidence / 100,
              color: barColor,
              percent: confidence,
            ),
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Recommendations', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              ...recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(rec, style: AppTextStyles.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard({
    required String title,
    required int percentage,
    required String description,
    required Color color,
    bool showProgress = true,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(height: 1.2),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(description, style: AppTextStyles.bodySmall),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.cardElevated,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBar({
    required String label,
    required double value,
    required Color color,
    required int percent,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.labelMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.cardElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent%',
          style: AppTextStyles.labelMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
