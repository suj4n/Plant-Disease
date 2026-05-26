import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/navigation/app_navigator.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/page_background.dart';

/// History Screen Template
/// Shows scan history with weekly chart and filter options
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
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Unknown';
    }
  }

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
                // Header with search
                _buildHeader(context),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Weekly Scans Chart
                        _buildWeeklyScansCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Quick Stats Grid
                        _buildQuickStatsGrid(),
                        
                        const SizedBox(height: 20),
                        
                        // Filter chips
                        _buildFilterChips(),
                        
                        const SizedBox(height: 16),
                        
                        // Scan History List
                        Text('Scan History', style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 12),
                        _buildScanHistoryList(),
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
              currentIndex: 1,
              onTap: (index) => AppNavigator.goToTab(context, index, currentIndex: 1),
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
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() {
                        _searchQuery = v;
                        _applyFilters();
                      }),
                      style: AppTextStyles.bodySmall,
                      decoration: InputDecoration(
                        hintText: 'Search scan history...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.filter_list,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScansCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Scans', style: AppTextStyles.headlineSmall),
              Text(
                'This Week',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDayBar('Mon', 0.4),
                _buildDayBar('Tue', 0.7),
                _buildDayBar('Wed', 0.5),
                _buildDayBar('Thu', 0.9),
                _buildDayBar('Fri', 0.6),
                _buildDayBar('Sat', 0.3),
                _buildDayBar('Sun', 0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String day, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 70 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Scans',
            value: '${_allScans.length}',
            color: AppColors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            label: 'Healthy',
            value:
                '${_allScans.where((s) => s['isHealthy'] == true).length}',
            color: AppColors.emerald,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            label: 'Diseased',
            value:
                '${_allScans.where((s) => s['isHealthy'] == false).length}',
            color: AppColors.coral,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            label: 'Accuracy',
            value: '95%',
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedFilter = filter;
            _applyFilters();
          }),
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
              filter,
              style: AppTextStyles.chipText.copyWith(
                color: isSelected
                    ? AppColors.primaryForeground
                    : AppColors.mutedForeground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScanHistoryList() {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_filteredScans.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No scans found',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: _filteredScans.map((scan) {
        final disease = scan['disease'] as String? ?? 'Unknown';
        final isHealthy = scan['isHealthy'] as bool? ?? false;
        final conf = scan['confidence'] as int? ?? 0;
        final timeAgo = _formatTimeAgo(scan['timestamp'] as String?);
        final statusColor = isHealthy ? AppColors.emerald : AppColors.coral;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isHealthy ? Icons.check_circle : Icons.warning_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(disease, style: AppTextStyles.titleSmall),
                      Text(timeAgo, style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$conf%',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: statusColor,
                      ),
                    ),
                    Text('confidence', style: AppTextStyles.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
