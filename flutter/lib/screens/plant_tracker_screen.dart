import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/navigation/app_navigator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/progress_widgets.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/page_background.dart';

/// Plant Tracker Screen Template
/// Shows plant growth charts, health timeline, and stage progress
class PlantTrackerScreen extends StatefulWidget {
  const PlantTrackerScreen({super.key});

  @override
  State<PlantTrackerScreen> createState() => _PlantTrackerScreenState();
}

class _PlantTrackerScreenState extends State<PlantTrackerScreen> {
  int _selectedPlantIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Tea plantation background image
          const PageBackground(
            imagePath: AppAssets.bg,
            overlayOpacity: 0.7,
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plant selector
                        _buildPlantSelector(),
                        
                        const SizedBox(height: 20),
                        
                        // Growth Rate Chart
                        _buildGrowthRateCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Health Timeline Card
                        _buildHealthTimelineCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Stats Grid
                        _buildStatsGrid(),
                        
                        const SizedBox(height: 20),
                        
                        // Stage Progress
                        Text('Growth Stage', style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 12),
                        const StageProgressIndicator(currentStage: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PlantDocBottomNav(
              currentIndex: 2,
              onTap: (index) => AppNavigator.goToTab(context, index, currentIndex: 2),
              onScanTap: () => AppNavigator.goToScan(context),
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.foreground,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Potato Crop Overview',
            style: AppTextStyles.headlineSmall,
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.more_horiz,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSelector() {
    final plants = ['Potato', 'Rice', 'Tomato', 'Wheat'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(plants.length, (index) {
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
                plants[index],
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
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Growth Rate', style: AppTextStyles.headlineSmall),
                  Text(
                    'Day 01 - 83 Plant Age',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Row(
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
                AppColors.emerald.withOpacity(0.6),
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
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Left side - text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Days Since Planting',
                      style: AppTextStyles.labelMedium,
                    ),
                    const Spacer(),
                    Text(
                      'To Harvest in',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      '20 Days',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Potato Crop\nHealth Timeline',
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
          
          const SizedBox(width: 16),
          
          // Right side - circular progress
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
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
