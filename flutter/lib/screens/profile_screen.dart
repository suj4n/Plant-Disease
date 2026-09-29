import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatting.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/section_header.dart';

const String kAppVersion = '3.1.0';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your scans and plants stay on this phone. You can log back in '
          'any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final message = await context.read<AuthProvider>().setBiometricEnabled(enabled);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showInfo(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body, style: AppTextStyles.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppShell(
      body: AppScrollBody(
        children: [
          Text('Profile', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          _ProfileHeader(name: auth.displayName),
          const SizedBox(height: AppSpacing.xl),

          if (auth.isAuthenticated) ...[
            const SectionHeader(title: 'Security'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: _SwitchRow(
                icon: Icons.fingerprint_rounded,
                label: 'Fingerprint login',
                description: 'Log in with your fingerprint instead of your password',
                value: auth.biometricEnabled,
                onChanged: _toggleBiometric,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Scan reminders',
                  description: 'Notify me when a plant is due for a check',
                  value: _notificationsOn,
                  onChanged: (v) => setState(() => _notificationsOn = v),
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  trailing: 'English',
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.light_mode_outlined,
                  label: 'Appearance',
                  trailing: 'Light',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Application'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.eco_outlined,
                  label: 'About PlantDoc',
                  onTap: () => _showInfo(
                    'About PlantDoc',
                    'PlantDoc detects plant diseases from a leaf photo using a '
                        'MobileNetV2 model trained on 20 plant and disease '
                        'classes across apple, potato, strawberry and tomato. '
                        'The model runs on your phone, so scans work offline.\n\n'
                        'Results are AI suggestions, not confirmed diagnoses. '
                        'Confirm with a local agricultural extension officer '
                        'before treating a valuable crop.',
                  ),
                ),
                const _RowDivider(),
                _ActionRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy',
                  onTap: () => _showInfo(
                    'Privacy',
                    'Your account, scans and plants are stored only on this '
                        'phone. Passwords are kept as a one-way hash, never as '
                        'text.\n\n'
                        'Leaf photos are analysed on the phone. Only if that '
                        'fails is a photo sent to the PlantDoc server, and it is '
                        'not kept there.',
                  ),
                ),
                const _RowDivider(),
                _ActionRow(
                  icon: Icons.description_outlined,
                  label: 'Terms of use',
                  onTap: () => _showInfo(
                    'Terms of use',
                    'PlantDoc is provided for guidance only. Detection results '
                        'are probabilistic and can be wrong, particularly on '
                        'unclear photos or plants outside the 20 supported '
                        'classes.\n\n'
                        'Always confirm a diagnosis before applying treatment.',
                  ),
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  trailing: kAppVersion,
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.cloud_outlined,
                  label: 'Server',
                  trailing: ApiService.isConfiguredForProduction
                      ? 'Cloud'
                      : 'Development',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (auth.isAuthenticated)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Create an account'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/welcome', (_) => false),
                child: const Text('Log in'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});

  /// Null for a guest.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'Guest';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: name == null
                ? const Icon(Icons.person_outline_rounded,
                    size: 30, color: AppColors.primaryDark)
                : Text(
                    firstNameFrom(displayName, fallback: 'P')
                        .characters
                        .first
                        .toUpperCase(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  name == null
                      ? 'Guest mode \u00b7 1 plant batch'
                      : 'Account on this phone',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: AppSpacing.md + 34,
        endIndent: AppSpacing.md,
      );
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.label,
    required this.trailing,
    this.description,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      // 56dp minimum row height keeps every target comfortably tappable.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.titleMedium),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(description!, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          trailing,
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: row,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      description: description,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.onPrimary,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      trailing: Text(trailing, style: AppTextStyles.bodySmall),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      onTap: onTap,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.muted,
      ),
    );
  }
}
