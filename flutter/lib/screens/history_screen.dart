import 'package:flutter/material.dart';

import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatting.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/scan_activity_tile.dart';
import '../core/widgets/state_views.dart';
import '../data/models/detection_result.dart';

enum HistoryFilter { all, healthy, diseased }

/// Past diagnoses, searchable and filterable.
///
/// Search and filtering run over the already-loaded local list, so they keep
/// working with no network.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _all = const [];
  ViewStatus _status = ViewStatus.loading;
  HistoryFilter _filter = HistoryFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted && _status != ViewStatus.loading) {
      setState(() => _status = ViewStatus.loading);
    }
    final scans = await ScanStorage.getAll();
    if (!mounted) return;
    setState(() {
      _all = scans;
      _status = scans.isEmpty ? ViewStatus.empty : ViewStatus.ready;
    });
  }

  List<Map<String, dynamic>> get _visible {
    final query = _query.trim().toLowerCase();
    return _all.where((scan) {
      final healthy = scan['isHealthy'] == true;
      final matchesFilter = switch (_filter) {
        HistoryFilter.all => true,
        HistoryFilter.healthy => healthy,
        HistoryFilter.diseased => !healthy,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final haystack = [
        scan['disease']?.toString() ?? '',
        scan['plant']?.toString() ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all scans?'),
        content: const Text(
          'This permanently removes every saved diagnosis. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ScanStorage.clearAll();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return AppShell(
      onRefresh: _load,
      body: Column(
        children: [
          _Header(
            total: _all.length,
            onClear: _all.isEmpty ? null : _confirmClear,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by disease or plant',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterRow(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildList(visible)),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> visible) {
    if (_status == ViewStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: LoadingState(rows: 5),
      );
    }

    if (_all.isEmpty) {
      return _centered(
        const EmptyState(
          icon: Icons.history_rounded,
          title: 'No scans yet',
          message:
              'Scan your first plant to start building your plant health '
              'history.',
        ),
      );
    }

    if (visible.isEmpty) {
      return _centered(
        EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: _query.isNotEmpty
              ? 'Nothing matches "$_query". Try a different search.'
              : 'No scans in this category yet.',
          actionLabel: 'Show all scans',
          onAction: () {
            _searchController.clear();
            setState(() {
              _query = '';
              _filter = HistoryFilter.all;
            });
          },
          compact: true,
        ),
      );
    }

    // ListView.builder so only visible rows are built, however long the
    // history gets.
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppScrollBody.navClearance(context),
      ),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final scan = visible[index];
        return ScanActivityTile(
          title: scan['disease']?.toString() ?? 'Unknown',
          plant: scan['plant']?.toString(),
          subtitle: formatRelativeTimestamp(scan['timestamp']),
          confidence: confidencePercentOf(scan['confidence']),
          isHealthy: scan['isHealthy'] == true,
          isIdentifiable: scan['isIdentifiable'] as bool? ?? true,
          imagePath: scan['imagePath'] as String?,
        );
      },
    );
  }

  Widget _centered(Widget child) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppScrollBody.navClearance(context),
        ),
        children: [child],
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onClear});

  final int total;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan history', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'Your diagnoses will appear here'
                      : '$total ${total == 1 ? 'scan' : 'scans'} saved',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear all scans',
              iconSize: 22,
            ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});

  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      HistoryFilter.all: 'All',
      HistoryFilter.healthy: 'Healthy',
      HistoryFilter.diseased: 'Diseased',
    };

    return SizedBox(
      // 48dp so each chip clears the Android touch-target minimum.
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _Chip(
                label: entry.value,
                selected: selected == entry.key,
                onTap: () => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTextStyles.labelLarge
                    .withWeight(selected ? FontWeight.w600 : FontWeight.w500)
                    .copyWith(
                      color:
                          selected ? AppColors.onPrimary : AppColors.foreground,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
