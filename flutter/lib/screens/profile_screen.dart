import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return AppShell(
      navIndex: 3,
      appBar: AppBar(title: const Text('Profile')),
      body: AppScrollBody(
        children: [
          _ProfileHeader(authProvider: authProvider),
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            authProvider: authProvider,
            notificationsOn: _notificationsOn,
            onNotificationsChanged: (v) => setState(() => _notificationsOn = v),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.authProvider});

  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    final email = authProvider.user?.email ?? 'guest@plantdoc.app';
    final fullName = authProvider.userProfile?['full_name'] as String? ?? 'PlantDoc User';

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.person_outline, color: AppColors.primary, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(fullName, style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(email, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.authProvider,
    required this.notificationsOn,
    required this.onNotificationsChanged,
  });

  final AuthProvider authProvider;
  final bool notificationsOn;
  final ValueChanged<bool> onNotificationsChanged;

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of PlantDoc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            trailing: Switch(
              value: notificationsOn,
              onChanged: onNotificationsChanged,
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Privacy',
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const Divider(height: 1),
          if (authProvider.isAuthenticated)
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              onTap: () => _handleLogout(context),
            ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppRadius.card,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTextStyles.titleMedium),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.bodySmall) : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.muted, size: 22)
              : null),
    );
  }
}

