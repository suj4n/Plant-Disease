import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/navigation/app_navigator.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_icon_button.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/page_background.dart';
import '../core/widgets/scan_activity_tile.dart';
import '../core/widgets/section_header.dart';
import '../features/plant_tracker/models/plant_batch.dart';
import '../features/plant_tracker/providers/plant_batch_provider.dart';
import '../features/plant_tracker/widgets/create_batch_sheet.dart';
import '../features/plant_tracker/widgets/home_batch_tile.dart';
import 'plant_batch_detail_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantBatchProvider>().loadBatches();
    });
  }

  Future<void> _loadData() async {
    final all = await ScanStorage.getAll();
    if (!mounted) return;
    setState(() => _recentScans = all.take(3).toList());
  }

  void _openBatchDetail(String batchId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlantBatchDetailScreen(batchId: batchId),
      ),
    ).then((_) {
      if (mounted) context.read<PlantBatchProvider>().loadBatches();
    });
  }

  Future<void> _createBatch() async {
    final result = await CreateBatchSheet.show(context);
    if (result == null || !mounted) return;

    final batch = await context.read<PlantBatchProvider>().createBatch(
          name: result['name'] as String,
          plantType: result['plantType'] as String,
          plantedDate: result['plantedDate'] as DateTime,
        );
    if (!mounted || batch == null) return;
    _openBatchDetail(batch.id);
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
            _HomeBatchesSection(
              onBatchTap: _openBatchDetail,
              onAddBatch: _createBatch,
              onViewAll: () => AppNavigator.goToTab(context, 2, currentIndex: 0),
            ),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final fullName = authProvider.userProfile?['full_name'] as String? ?? 'PlantDoc User';
    final firstName = fullName.split(' ').first;

    return Row(
      children: [
        const AppIconButton(icon: Icons.person_outline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning', style: AppTextStyles.bodySmall),
              Text(firstName, style: AppTextStyles.headlineSmall),
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

class _HomeBatchesSection extends StatelessWidget {
  const _HomeBatchesSection({
    required this.onBatchTap,
    required this.onAddBatch,
    required this.onViewAll,
  });

  final void Function(String batchId) onBatchTap;
  final VoidCallback onAddBatch;
  final VoidCallback onViewAll;

  static const _slotCount = 4;

  List<PlantBatch> _batchesForGrid(List<PlantBatch> all) {
    final sorted = List<PlantBatch>.from(all)
      ..sort((a, b) => a.nextReminderDate.compareTo(b.nextReminderDate));
    return sorted.take(_slotCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantBatchProvider>(
      builder: (context, provider, _) {
        final batches = _batchesForGrid(provider.batches);
        final showAddSlots = batches.length < _slotCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Your plant batches',
              actionLabel: provider.isEmpty ? null : 'View all',
              onAction: provider.isEmpty ? null : onViewAll,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (provider.loading)
              const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.isEmpty)
              AppCard(
                onTap: onAddBatch,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No batches yet',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track plantings and get scan reminders every 2 weeks.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1,
                children: [
                  for (final batch in batches)
                    HomeBatchTile(
                      batch: batch,
                      onTap: () => onBatchTap(batch.id),
                    ),
                  if (showAddSlots)
                    for (var i = 0; i < _slotCount - batches.length; i++)
                      HomeAddBatchTile(onTap: onAddBatch),
                ],
              ),
          ],
        );
      },
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
