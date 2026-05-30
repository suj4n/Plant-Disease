import 'package:flutter/material.dart';
import '../core/constants/app_stats.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/progress_widgets.dart';
import '../core/widgets/section_header.dart';

/// Plant Tracker Screen Template
/// Shows plant growth charts, health timeline, and stage progress
class PlantTrackerScreen extends StatefulWidget {
  const PlantTrackerScreen({super.key, this.initialCropIndex = 0});

  final int initialCropIndex;

  @override
  State<PlantTrackerScreen> createState() => _PlantTrackerScreenState();
}

class _PlantTrackerScreenState extends State<PlantTrackerScreen> {
  late int _selectedPlantIndex;

  @override
  void initState() {
    super.initState();
    _selectedPlantIndex = widget.initialCropIndex.clamp(
      0,
      AppStats.crops.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navIndex: 2,
      appBar: AppBar(
        title: Text('${AppStats.supportedCrops[_selectedPlantIndex]} overview'),
      ),
      body: AppScrollBody(
        children: [
          _buildPlantSelector(),
          const SizedBox(height: AppSpacing.md),
          _buildGrowthRateCard(),
          const SizedBox(height: AppSpacing.md),
          _buildHealthTimelineCard(),
          const SizedBox(height: AppSpacing.md),
          _buildStatsGrid(),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Growth stage'),
          const SizedBox(height: AppSpacing.sm),
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: StageProgressIndicator(currentStage: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(AppStats.supportedCrops.length, (index) {
          final plant = AppStats.supportedCrops[index];
          final isSelected = _selectedPlantIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlantIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                plant,
                style: AppTextStyles.chipText.copyWith(
                  color: isSelected 
                      ? AppColors.primaryForeground 
                      : AppColors.mutedForeground,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrowthRateCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Growth Rate', style: AppTextStyles.headlineSmall),
                    Text(
                      'Day 01 - 83 Plant Age',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Plant Height (cm)',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '83 Days',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Bar Chart
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.2, '0'),
                _buildBar(0.3, '15'),
                _buildBar(0.45, '30'),
                _buildBar(0.6, '45'),
                _buildBar(0.75, '60'),
                _buildBar(0.85, '75'),
                _buildBar(1.0, '90'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // X-axis label
          Center(
            child: Text(
              'Days Since Planting',
              style: AppTextStyles.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 120 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.emerald,
                AppColors.success.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }

  Widget _buildHealthTimelineCard() {
    final cropName = AppStats.supportedCrops[_selectedPlantIndex];

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Days Since Planting',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To Harvest in',
                        style: AppTextStyles.labelSmall,
                      ),
                      Text(
                        '20 Days',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$cropName Crop\nHealth Timeline',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Track growth metrics for\nyour planted field',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const DaysCountdownRing(
            daysRemaining: 63,
            totalDays: 90,
            size: 90,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.water_drop,
            label: 'Water Depth',
            value: '50%',
            color: AppColors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.eco,
            label: 'Plant Health',
            value: '80%',
            color: AppColors.emerald,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: AppTextStyles.headlineSmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
