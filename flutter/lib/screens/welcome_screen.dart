import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_stats.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_assets.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/photo_band.dart';
import '../core/widgets/crop_strip.dart';

/// Welcome and sign-in. Supabase auth is unchanged; only the surface moved.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _enterApp();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ??
                "We couldn't sign you in. Check your email and password.",
          ),
        ),
      );
  }

  void _enterApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // "Continue as guest" is pinned below the scroll view rather than sitting
      // at the end of it. Previously the whole page was one scroll: it happened
      // to fit a 360x800 phone, but any shorter screen or a larger system font
      // pushed the guest entry off-screen, hiding the only way into the app for
      // someone without an account.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _WelcomeHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _LoginCard(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: _isLoading,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onLogin: _handleLogin,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _CapabilityRow(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _GuestEntry(onContinue: _enterApp),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wordmark over a field photograph.
///
/// This *replaces* the plain text header rather than sitting above it, so the
/// sign-in card does not move — the 200px hero that previously pushed the form
/// below the fold is exactly what this is designed not to repeat.
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return PhotoBand(
      image: AppAssets.fieldTerraces,
      height: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PlantDoc',
            style: AppTextStyles.displayMedium
                .copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Spot plant disease early, from a single leaf photo.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => onLogin(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (v.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.mutedForeground,
                      ),
                    )
                  : const Text('Log in'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?", style: AppTextStyles.bodySmall),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What the model covers, shown rather than described.
class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: CropStrip(
        caption: '${AppStats.diseaseCount} diseases across '
            '${AppStats.cropCount} crops',
      ),
    );
  }
}

class _GuestEntry extends StatelessWidget {
  const _GuestEntry({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Or try it without an account',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
          label: const Text('Continue as guest'),
        ),
      ],
    );
  }
}
