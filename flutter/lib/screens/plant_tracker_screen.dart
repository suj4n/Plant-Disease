import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/page_background.dart';
import '../features/plant_tracker/providers/plant_batch_provider.dart';
import '../features/plant_tracker/widgets/create_batch_sheet.dart';
import '../features/plant_tracker/widgets/plant_batch_card.dart';
import 'plant_batch_detail_screen.dart';

/// Plant batches dashboard with local storage and scan reminders.
class PlantTrackerScreen extends StatefulWidget {
  const PlantTrackerScreen({super.key, this.suggestedPlantType});

  /// Optional plant type pre-selected when opening from home crop grid.
  final String? suggestedPlantType;

  @override
  State<PlantTrackerScreen> createState() => _PlantTrackerScreenState();
}

class _PlantTrackerScreenState extends State<PlantTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantBatchProvider>().loadBatches();
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

    if (!mounted) return;
    if (batch != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch saved — reminders scheduled every 2 weeks'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _openDetail(batch.id);
    }
  }

  void _openDetail(String batchId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlantBatchDetailScreen(batchId: batchId),
      ),
    ).then((_) {
      if (mounted) {
        context.read<PlantBatchProvider>().loadBatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navIndex: 2,
      background: const PageBackground(overlayOpacity: 0.72),
      appBar: AppBar(
        title: const Text('Plant Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add batch',
            onPressed: _openCreateBatch,
          ),
        ],
      ),
      body: Consumer<PlantBatchProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.loadBatches,
            child: AppScrollBody(
              children: [
                if (provider.isEmpty)
                  _EmptyState(
                    suggestedPlantType: widget.suggestedPlantType,
                    onCreate: () => _openCreateBatch(
                      plantType: widget.suggestedPlantType,
                    ),
                  )
                else ...[
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onCreate,
    this.suggestedPlantType,
  });

  final VoidCallback onCreate;
  final String? suggestedPlantType;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.primaryGlow,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 36,
              color: AppColors.onPrimary,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No plant batches yet',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            suggestedPlantType != null
                ? 'Create a batch for your $suggestedPlantType crop and we\'ll remind you to scan every 2 weeks.'
                : 'Add your first batch with a name, crop type, and planting date.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create plant batch'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }
}
