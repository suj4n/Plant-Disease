import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

/// Exhaustive screen states, so no screen improvises its own.
enum ViewStatus { loading, ready, empty, error }

/// Friendly "nothing here yet" panel with an optional way forward.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional content below the action — e.g. the supported-crop strip, which
  /// answers "what can I track?" at the moment the user asks it.
  final Widget? footer;

  /// Inline variant for a section inside a longer screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 48 : 64,
            height: compact ? 48 : 64,
            decoration: const BoxDecoration(
              color: AppColors.cardElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 24 : 30,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          if (footer != null) ...[
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            const Divider(height: 1),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Human-readable failure panel. Never render a raw exception here.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
    this.compact = false,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: compact ? 48 : 64,
            height: compact ? 48 : 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: compact ? 24 : 30,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Text(title, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton placeholders. Shape mirrors the real content, so the screen does
/// not visibly jump when data lands.
class LoadingState extends StatefulWidget {
  const LoadingState({super.key, this.rows = 3, this.rowHeight = 76});

  final int rows;
  final double rowHeight;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Static skeletons when the user has asked for reduced motion.
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Column(
      children: List.generate(widget.rows, (i) {
        final skeleton = Container(
          height: widget.rowHeight,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: AppRadius.card,
          ),
        );
        if (!animate) return skeleton;
        return FadeTransition(
          opacity: Tween(begin: 0.45, end: 0.9).animate(_controller),
          child: skeleton,
        );
      }),
    );
  }
}
