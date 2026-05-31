import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_stats.dart';
import '../core/navigation/app_navigator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/page_background.dart';
import '../features/plant_tracker/models/plant_batch.dart';
import '../features/plant_tracker/providers/plant_batch_provider.dart';
import '../features/plant_tracker/widgets/batch_timeline.dart';
import '../features/plant_tracker/widgets/create_batch_sheet.dart';

class PlantBatchDetailScreen extends StatefulWidget {
  const PlantBatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  State<PlantBatchDetailScreen> createState() => _PlantBatchDetailScreenState();
}

class _PlantBatchDetailScreenState extends State<PlantBatchDetailScreen> {
  PlantBatch? _batch;
  List<BatchTimelineEvent> _timeline = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<PlantBatchProvider>();
    final batch = await provider.getBatch(widget.batchId);
    final timeline = await provider.getTimeline(widget.batchId);
    if (!mounted) return;
    setState(() {
      _batch = batch;
      _timeline = timeline;
      _loading = false;
    });
  }

  Future<void> _editBatch() async {
    final batch = _batch;
    if (batch == null) return;

    final result = await CreateBatchSheet.show(
      context,
      initialName: batch.name,
      initialPlantType: batch.plantType,
      initialPlantedDate: batch.plantedDate,
      title: 'Edit batch',
      submitLabel: 'Update batch',
    );
    if (result == null || !mounted) return;

    final ok = await context.read<PlantBatchProvider>().updateBatch(
          id: batch.id,
          name: result['name'] as String,
          plantType: result['plantType'] as String,
          plantedDate: result['plantedDate'] as DateTime,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    }
  }

  Future<void> _deleteBatch() async {
    final batch = _batch;
    if (batch == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text('Delete batch?'),
        content: Text(
          'Remove "${batch.name}" and cancel its reminders?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok =
        await context.read<PlantBatchProvider>().deleteBatch(batch.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    }
  }

  Future<void> _triggerScan() async {
    final batch = _batch;
    if (batch == null) return;

    await context.read<PlantBatchProvider>().recordScan(batch.id);
    if (!mounted) return;
    AppNavigator.goToScan(context);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_batch?.name ?? 'Batch details'),
        actions: [
          if (_batch != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editBatch();
                  case 'delete':
                    _deleteBatch();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PageBackground(overlayOpacity: 0.72),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_batch == null)
            Center(
              child: Text('Batch not found', style: AppTextStyles.bodyLarge),
            )
          else
            _buildContent(_batch!),
        ],
      ),
    );
  }

  Widget _buildContent(PlantBatch batch) {
    final crop = AppStats.cropByName(batch.plantType);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: crop.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(crop.icon, color: crop.color, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(batch.plantType, style: AppTextStyles.bodySmall),
                        Text(batch.name, style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${batch.daysSincePlanted} days since planting',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    label: 'Planted',
                    value: batch.plantedDateLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _InfoChip(
                    label: 'Next reminder',
                    value: batch.nextReminderLabel,
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Timeline', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: BatchTimeline(events: _timeline),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _triggerScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan for diseases'),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _editBatch,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit batch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: highlight ? AppColors.primary : AppColors.foreground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
