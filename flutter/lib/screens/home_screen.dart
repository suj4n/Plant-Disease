import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/app_navigator.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatting.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_icon_button.dart';
import '../core/widgets/app_shell.dart';
import '../core/constants/app_assets.dart';
import '../core/widgets/crop_strip.dart';
import '../core/widgets/photo_band.dart';
import '../core/widgets/scan_activity_tile.dart';
import '../core/widgets/section_header.dart';
import '../core/widgets/state_views.dart';
import '../data/models/detection_result.dart';
import '../features/plant_tracker/models/plant_batch.dart';
import '../features/plant_tracker/providers/plant_batch_provider.dart';
import '../features/plant_tracker/widgets/create_batch_sheet.dart';
import '../features/plant_tracker/widgets/home_batch_tile.dart';
import 'plant_batch_detail_screen.dart';

/// Home answers three questions at a glance: who you are, how your plants are,
/// and how to scan. Every section degrades to an empty state, so the screen is
/// complete with no history, no plants and no network.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentScans = const [];
  ViewStatus _scansStatus = ViewStatus.loading;

  @override
  void initState() {
    super.initState();
    _loadScans();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlantBatchProvider>().loadBatches();
    });
  }

  Future<void> _loadScans() async {
    if (mounted && _scansStatus != ViewStatus.loading) {
      setState(() => _scansStatus = ViewStatus.loading);
    }
    // ScanStorage is local-first, so this succeeds offline.
    final recent = await ScanStorage.getRecent(3);
    if (!mounted) return;
    setState(() {
      _recentScans = recent;
      _scansStatus = recent.isEmpty ? ViewStatus.empty : ViewStatus.ready;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadScans(),
      context.read<PlantBatchProvider>().loadBatches(),
    ]);
  }

  void _openScan() {
    AppNavigator.goToScan(context).then((_) {
      if (mounted) _loadScans();
    });
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      onRefresh: _refresh,
      body: AppScrollBody(
        children: [
          const _HomeHeader(),
          const SizedBox(height: AppSpacing.lg),
          _ScanCallout(onScan: _openScan),
          const SizedBox(height: AppSpacing.xl),
          _PlantBatchesSection(
            onBatchTap: _openBatchDetail,
            onAddBatch: _createBatch,
            onViewAll: () =>
                AppNavigator.goToTab(context, AppNavigator.plantsTab),
          ),
          const SizedBox(height: AppSpacing.xl),
          _RecentDiagnosesSection(
            status: _scansStatus,
            scans: _recentScans,
            onScan: _openScan,
            onViewAll: () =>
                AppNavigator.goToTab(context, AppNavigator.historyTab),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;
    final name = firstNameOrNull(profile?['full_name'] as String?);
    final avatarUrl = profile?['avatar_url'] as String?;

    // A signed-out user has no name, and "Good evening, there" reads oddly.
    final greeting = name == null
        ? greetingFor(DateTime.now())
        : '${greetingFor(DateTime.now())}, $name';

    return PhotoBand(
      image: AppAssets.fieldFoliage,
      height: 116,
      child: Row(
        children: [
          // Avatar and bell keep solid fills: interactive controls do not sit
          // directly on photography.
          _Avatar(url: avatarUrl, initial: name ?? 'P'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.onPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Let's keep your plants healthy.",
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.onPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: Icons.notifications_none_rounded,
            semanticLabel: 'Reminders',
            onTap: () => AppNavigator.goToTab(context, AppNavigator.plantsTab),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initial});

  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    // The home screen must work with no profile image, so the initial is the
    // default rather than a fallback nobody designed.
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        image: (url != null && url!.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: (url == null || url!.isEmpty)
          ? Text(
              initial.characters.first.toUpperCase(),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.muted,
              ),
            )
          : null,
    );
  }
}

/// The screen's one primary action.
///
/// This replaced a full-bleed stock photo *and* a separate "scan now" card —
/// two blocks competing to say the same thing, with a decorative photograph
/// carrying none of the message. Type and one button say it in a third of the
/// height.
class _ScanCallout extends StatelessWidget {
  const _ScanCallout({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Healthy plants start with early detection.',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Photograph one affected leaf and PlantDoc AI will suggest what '
            'to look for.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.center_focus_strong_rounded, size: 19),
              label: const Text('Scan a plant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantBatchesSection extends StatelessWidget {
  const _PlantBatchesSection({
    required this.onBatchTap,
    required this.onAddBatch,
    required this.onViewAll,
  });

  final void Function(String batchId) onBatchTap;
  final VoidCallback onAddBatch;
  final VoidCallback onViewAll;

  static const _slotCount = 4;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantBatchProvider>(
      builder: (context, provider, _) {
        final sorted = List<PlantBatch>.from(provider.batches)
          ..sort((a, b) => a.nextReminderDate.compareTo(b.nextReminderDate));
        final batches = sorted.take(_slotCount).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Your plants',
              actionLabel: provider.isEmpty ? null : 'View all',
              onAction: provider.isEmpty ? null : onViewAll,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (provider.loading)
              const LoadingState(rows: 2, rowHeight: 100)
            else if (provider.isEmpty)
              EmptyState(
                icon: Icons.local_florist_outlined,
                title: 'No plants yet',
                message:
                    'Add your first planting to track its progress and get '
                    'a scan reminder every two weeks.',
                actionLabel: 'Add a plant',
                onAction: onAddBatch,
                compact: true,
                footer: const CropStrip(thumbSize: 44),
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
                  if (batches.length < _slotCount)
                    HomeAddBatchTile(onTap: onAddBatch),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _RecentDiagnosesSection extends StatelessWidget {
  const _RecentDiagnosesSection({
    required this.status,
    required this.scans,
    required this.onScan,
    required this.onViewAll,
  });

  final ViewStatus status;
  final List<Map<String, dynamic>> scans;
  final VoidCallback onScan;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent diagnoses',
          actionLabel: scans.isEmpty ? null : 'View all',
          onAction: scans.isEmpty ? null : onViewAll,
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (status) {
          ViewStatus.loading => const LoadingState(rows: 2),
          ViewStatus.empty || ViewStatus.error => EmptyState(
              icon: Icons.center_focus_weak_rounded,
              title: 'No scans yet',
              message:
                  'Scan your first plant to start building your plant health '
                  'history.',
              actionLabel: 'Scan a plant',
              onAction: onScan,
              compact: true,
            ),
          ViewStatus.ready => Column(
              children: [
                for (final scan in scans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ScanActivityTile(
                      title: scan['disease']?.toString() ?? 'Unknown',
                      plant: scan['plant']?.toString(),
                      subtitle: formatRelativeTimestamp(scan['timestamp']),
                      confidence: confidencePercentOf(scan['confidence']),
                      isHealthy: scan['isHealthy'] == true,
                      isIdentifiable: scan['isIdentifiable'] as bool? ?? true,
                      imagePath: scan['imagePath'] as String?,
                    ),
                  ),
              ],
            ),
        },
      ],
    );
  }
}
