import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/crop_strip.dart';
import '../core/widgets/state_views.dart';
import '../features/plant_tracker/providers/plant_batch_provider.dart';
import '../features/plant_tracker/widgets/create_batch_sheet.dart';
import '../features/plant_tracker/widgets/plant_batch_card.dart';
import 'plant_batch_detail_screen.dart';

/// Plant batches with local storage and two-weekly scan reminders.
/// Behaviour is unchanged; only the presentation moved to the new system.
class PlantTrackerScreen extends StatefulWidget {
  const PlantTrackerScreen({super.key, this.suggestedPlantType});

  /// Optional plant type pre-selected when opening from elsewhere.
  final String? suggestedPlantType;

  @override
  State<PlantTrackerScreen> createState() => _PlantTrackerScreenState();
}

class _PlantTrackerScreenState extends State<PlantTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlantBatchProvider>().loadBatches();
    });
  }

  Future<void> _openCreateBatch({String? plantType}) async {
    final result = await CreateBatchSheet.show(
      context,
      initialPlantType: plantType ?? widget.suggestedPlantType,
    );
    if (result == null || !mounted) return;

    final batch = await context.read<PlantBatchProvider>().createBatch(
          name: result['name'] as String,
          plantType: result['plantType'] as String,
          plantedDate: result['plantedDate'] as DateTime,
        );

    if (!mounted || batch == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Plant saved. We will remind you to scan every 2 weeks.'),
        ),
      );
    _openDetail(batch.id);
  }

  void _openDetail(String batchId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlantBatchDetailScreen(batchId: batchId),
      ),
    ).then((_) {
      if (mounted) context.read<PlantBatchProvider>().loadBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantBatchProvider>(
      builder: (context, provider, _) {
        return AppShell(
          onRefresh: provider.loadBatches,
          body: AppScrollBody(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My plants', style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          provider.isEmpty
                              ? 'Track a planting to get scan reminders'
                              : '${provider.batches.length} '
                                  '${provider.batches.length == 1 ? 'planting' : 'plantings'} tracked',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!provider.isEmpty)
                    IconButton(
                      onPressed: _openCreateBatch,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      tooltip: 'Add a plant',
                      iconSize: 24,
                      color: AppColors.primaryDark,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (provider.loading)
                const LoadingState(rows: 3, rowHeight: 110)
              else if (provider.isEmpty)
                EmptyState(
                  icon: Icons.local_florist_outlined,
                  title: 'Add your first plant',
                  message: widget.suggestedPlantType != null
                      ? 'Track your ${widget.suggestedPlantType} crop and we '
                          'will remind you to scan it every two weeks.'
                      : 'Add a planting with a name, crop type and planting '
                          'date, and we will remind you to scan it every two '
                          'weeks.',
                  actionLabel: 'Add a plant',
                  onAction: () =>
                      _openCreateBatch(plantType: widget.suggestedPlantType),
                  footer: const CropStrip(
                    thumbSize: 48,
                    caption: 'PlantDoc can track these crops',
                  ),
                )
              else
                for (var i = 0; i < provider.batches.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: PlantBatchCard(
                      batch: provider.batches[i],
                      animationIndex: i,
                      onTap: () => _openDetail(provider.batches[i].id),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
