import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_stats.dart';
import '../core/navigation/app_page_route.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/highlight_chip.dart';
import '../core/widgets/page_background.dart';
import 'home_screen.dart';

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _enterApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _enterApp() {
    AppPageRoute.pushReplacementFade(
      context,
      const HomeScreen(),
      duration: AppPageRoute.welcomeDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageBackground(
            imagePath: AppAssets.welcomeBg,
            gradientOverlay: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x66000000),
                Color(0xE60A1410),
                AppColors.background,
              ],
              stops: [0.0, 0.35, 0.72, 1.0],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                children: [
                  const _WelcomeTitle(),
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
                  const SizedBox(height: AppSpacing.lg),
                  const Center(
                    child: HighlightChip(
                      icon: Icons.bolt_rounded,
                      value: 'Instant',
                      label: 'Diagnosis',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _StatsRow(),
                  const SizedBox(height: AppSpacing.lg),
                  _GuestEntry(onContinue: _enterApp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'WELCOME TO',
          style: AppTextStyles.labelLarge.copyWith(
            letterSpacing: 3,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('PlantDoc', style: AppTextStyles.displayLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'AI plant disease detection for farmers',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Save scans and sync across devices',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
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
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log in'),
            ),
            const SizedBox(height: AppSpacing.xs),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          HighlightChip(
            icon: Icons.coronavirus_outlined,
            value: AppStats.diseaseCount,
            label: 'Diseases',
          ),
          SizedBox(width: AppSpacing.sm),
          HighlightChip(
            icon: Icons.grass,
            value: AppStats.cropCount,
            label: 'Crops',
          ),
        ],
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
        Text('Or continue without signing in', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.eco_outlined, size: 20),
          label: const Text('Enter app'),
        ),
      ],
    );
  }
}
