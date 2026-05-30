import 'package:flutter/material.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/scan_activity_tile.dart';
import '../core/widgets/section_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Healthy', 'Diseased'];

  List<Map<String, dynamic>> _allScans = [];
  List<Map<String, dynamic>> _filteredScans = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    final scans = await ScanStorage.getAll();
    if (!mounted) return;
    setState(() {
      _allScans = scans;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    var result = List<Map<String, dynamic>>.from(_allScans);
    if (_selectedFilter == 'Healthy') {
      result = result.where((s) => s['isHealthy'] == true).toList();
    } else if (_selectedFilter == 'Diseased') {
      result = result.where((s) => s['isHealthy'] == false).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (s) => (s['disease']?.toString() ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    _filteredScans = result;
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
      navIndex: 1,
      appBar: AppBar(title: const Text('History')),
      body: AppScrollBody(
        children: [
          TextField(
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _applyFilters();
            }),
            decoration: const InputDecoration(
              hintText: 'Search scans',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _WeeklyChartCard(),
          const SizedBox(height: AppSpacing.md),
          _QuickStatsRow(scans: _allScans),
          const SizedBox(height: AppSpacing.md),
          _FilterChips(
            filters: _filters,
            selected: _selectedFilter,
            onSelected: (f) => setState(() {
              _selectedFilter = f;
              _applyFilters();
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Scan history'),
          const SizedBox(height: AppSpacing.sm),
          _ScanList(
            loading: _loading,
            scans: _filteredScans,
            formatTimeAgo: _formatTimeAgo,
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Weekly scans'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _DayBar(label: 'Mon', factor: 0.4),
                _DayBar(label: 'Tue', factor: 0.7),
                _DayBar(label: 'Wed', factor: 0.5),
                _DayBar(label: 'Thu', factor: 0.9),
                _DayBar(label: 'Fri', factor: 0.6),
                _DayBar(label: 'Sat', factor: 0.3),
                _DayBar(label: 'Sun', factor: 0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.label, required this.factor});

  final String label;
  final double factor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 64 * factor,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.scans});

  final List<Map<String, dynamic>> scans;

  @override
  Widget build(BuildContext context) {
    final healthy = scans.where((s) => s['isHealthy'] == true).length;
    final diseased = scans.where((s) => s['isHealthy'] == false).length;

    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Total', value: '${scans.length}', color: AppColors.indigo)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _StatTile(label: 'Healthy', value: '$healthy', color: AppColors.success)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _StatTile(label: 'Diseased', value: '$diseased', color: AppColors.error)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineSmall.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: filters.map((filter) {
        return ChoiceChip(
          label: Text(filter),
          selected: selected == filter,
          onSelected: (_) => onSelected(filter),
        );
      }).toList(),
    );
  }
}

class _ScanList extends StatelessWidget {
  const _ScanList({
    required this.loading,
    required this.scans,
    required this.formatTimeAgo,
  });

  final bool loading;
  final List<Map<String, dynamic>> scans;
  final String Function(String?) formatTimeAgo;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (scans.isEmpty) {
      return AppCard(
        child: Center(child: Text('No scans found', style: AppTextStyles.bodyMedium)),
      );
    }

    return Column(
      children: scans.map((scan) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: ScanActivityTile(
            title: scan['disease'] as String? ?? 'Unknown',
            subtitle: formatTimeAgo(scan['timestamp'] as String?),
            confidence: scan['confidence'] as int? ?? 0,
            isHealthy: scan['isHealthy'] as bool? ?? false,
          ),
        );
      }).toList(),
    );
  }
}
