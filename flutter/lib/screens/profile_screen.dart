import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/navigation/app_navigator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/page_background.dart';
import '../core/widgets/bottom_nav.dart';

/// Profile — avatar, username, and settings list.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _navIndex = 3;
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const PageBackground(
            imagePath: AppAssets.bg,
            overlayOpacity: 0.7,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Profile', style: AppTextStyles.displayMedium),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 28),
                        _buildSettingsCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 56,
          ),
        ),
        const SizedBox(height: 16),
        Text('PlantDoc User', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'user@plantdoc.app',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            trailing: Switch(
              value: _notificationsOn,
              activeThumbColor: AppColors.primaryForeground,
              activeTrackColor: AppColors.primary,
              onChanged: (v) => setState(() => _notificationsOn = v),
            ),
          ),
          _divider(),
          _settingsTile(
            icon: Icons.lock_outline,
            label: 'Privacy',
            onTap: () {},
          ),
          _divider(),
          _settingsTile(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () {},
          ),
          _divider(),
          _settingsTile(
            icon: Icons.info_outline,
            label: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.6),
        indent: 16,
        endIndent: 16,
      );

  Widget _settingsTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(label, style: AppTextStyles.titleSmall),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.labelSmall)
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.muted, size: 22)
              : null),
    );
  }
}
