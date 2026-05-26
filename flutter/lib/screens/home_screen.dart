import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/navigation/app_navigator.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/stat_widgets.dart';
import '../core/widgets/bottom_nav.dart';

/// Home Screen Template
/// Matches the PlantDoc design with hero section, stats, and plant cards
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  String _selectedCrop = 'All';

  int _totalScans = 0;
  int _healthyScans = 0;
  int _diseasedScans = 0;
  List<Map<String, dynamic>> _recentScans = [];
  bool _statsLoading = true;

  final List<String> _cropTypes = ['All', 'Rice', 'Tomato', 'Potato', 'Wheat', 'Corn'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await ScanStorage.getStats();
    final all = await ScanStorage.getAll();
    if (!mounted) return;
    setState(() {
      _totalScans = stats['total']!;
      _healthyScans = stats['healthy']!;
      _diseasedScans = stats['diseased']!;
      _recentScans = all.take(3).toList();
      _statsLoading = false;
    });
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
          // Hero Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Stack(
              children: [
                // Background image
                Image.asset(
                  AppAssets.homeHero,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A4D2E), AppColors.background],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x66000000),
                        AppColors.background,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Welcome text
                        _buildWelcomeSection(),
                        
                        const SizedBox(height: 20),
                        
                        // Stats row
                        _buildStatsRow(),
                        
                        const SizedBox(height: 24),
                        
                        // Crop filter
                        _buildCropFilter(),
                        
                        const SizedBox(height: 16),
                        
                        // Quick actions
                        _buildQuickActions(),
                        
                        const SizedBox(height: 24),
                        
                        // My Plants section
                        _buildMyPlantsSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Recent Activity
                        _buildRecentActivity(),
                        
                        const SizedBox(height: 100), // Bottom padding for nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PlantDocBottomNav(
              currentIndex: _navIndex,
              onTap: (index) => AppNavigator.goToTab(
                context,
                index,
                currentIndex: _navIndex,
              ),
              onScanTap: () => AppNavigator.goToScan(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.muted,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                'PlantDoc',
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),
          
          const Spacer(),
          
          // Notification bell
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.foreground,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are your',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          'crops today?',
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Nepal • May 2026',
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          StatBadge(
            icon: Icons.document_scanner,
            value: _statsLoading ? '...' : '$_totalScans',
            label: 'Total Scans',
            color: AppColors.indigo,
          ),
          const SizedBox(width: 8),
          StatBadge(
            icon: Icons.check_circle,
            value: _statsLoading ? '...' : '$_healthyScans',
            label: 'Healthy',
            color: AppColors.emerald,
          ),
          const SizedBox(width: 8),
          StatBadge(
            icon: Icons.warning_rounded,
            value: _statsLoading ? '...' : '$_diseasedScans',
            label: 'Diseased',
            color: AppColors.coral,
          ),
        ],
      ),
    );
  }

  Widget _buildCropFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _cropTypes.map((crop) {
          final isSelected = _selectedCrop == crop;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCrop = crop),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  crop,
                  style: AppTextStyles.chipText.copyWith(
                    color: isSelected 
                        ? AppColors.primaryForeground 
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            onTap: () {
              // Navigate to scan
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.emerald,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Scan Leaf', style: AppTextStyles.titleMedium),
                Text('Detect disease instantly', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            onTap: () {
              // Navigate to plants
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.indigo,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text('My Plants', style: AppTextStyles.titleMedium),
                Text('Track crop health', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyPlantsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Plants', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: AppColors.emerald,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Plant ${index + 1}',
                        style: AppTextStyles.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rice',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.emerald,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '95% Health',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentScans.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.eco, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No scans yet — tap Scan to start!',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ..._recentScans.map((scan) {
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
          }),
      ],
    );
  }
}
