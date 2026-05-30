import 'package:flutter/material.dart';
import '../core/constants/app_stats.dart';
import '../core/navigation/app_navigator.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_icon_button.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/crop_grid_tile.dart';
import '../core/widgets/page_background.dart';
import '../core/widgets/scan_activity_tile.dart';
import '../core/widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await ScanStorage.getAll();
    if (!mounted) return;
    setState(() => _recentScans = all.take(3).toList());
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Unknown';
    try {
      final diff = DateTime.now().difference(DateTime.parse(timestamp));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navIndex: 0,
      background: const HeroBackground(fullScreen: true),
      body: SafeArea(
        child: AppScrollBody(
          children: [
            _HomeHeader(),
            const SectionGap(size: AppSpacing.lg),
            const _WelcomeBlock(),
            const SectionGap(),
            const _SupportedCropsSection(),
            const SectionGap(),
            _RecentActivitySection(
              scans: _recentScans,
              formatTimeAgo: _formatTimeAgo,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppIconButton(icon: Icons.person_outline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning', style: AppTextStyles.bodySmall),
              Text('PlantDoc', style: AppTextStyles.headlineSmall),
            ],
          ),
        ),
        const AppIconButton(icon: Icons.notifications_outlined),
      ],
    );
  }
}

class _WelcomeBlock extends StatelessWidget {
  const _WelcomeBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are your',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.foregroundSecondary,
          ),
        ),
        Text('crops today?', style: AppTextStyles.displayMedium),
      ],
    );
  }
}

class _SupportedCropsSection extends StatelessWidget {
  const _SupportedCropsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Supported crops'),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1,
          children: [
            for (var i = 0; i < AppStats.crops.length; i++)
              CropGridTile(
                crop: AppStats.crops[i],
                onTap: () => AppNavigator.goToPlantTracker(
                  context,
                  cropIndex: i,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.scans,
    required this.formatTimeAgo,
  });

  final List<Map<String, dynamic>> scans;
  final String Function(String?) formatTimeAgo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: AppSpacing.sm),
        if (scans.isEmpty)
          AppCard(
            child: Row(
              children: [
                Icon(Icons.eco_outlined, color: AppColors.primary, size: 28),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No scans yet. Tap Scan to diagnose a plant.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...scans.map((scan) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ScanActivityTile(
                title: scan['disease'] as String? ?? 'Unknown',
                subtitle: formatTimeAgo(scan['timestamp'] as String?),
                confidence: scan['confidence'] as int? ?? 0,
                isHealthy: scan['isHealthy'] as bool? ?? false,
              ),
            );
          }),
      ],
    );
  }
}
