import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Floating bottom navigation: four tabs around a raised Scan action.
///
/// Scan is the app's primary job, so it gets the raised centre treatment rather
/// than a fifth equal tab. The bar sits inside a [SizedBox] tall enough to
/// contain the overhanging button, so its top half is actually tappable — as an
/// overflowing `Stack` child it was drawn but not hit-tested.
class PlantDocBottomNav extends StatelessWidget {
  const PlantDocBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanTap;

  static const double _barHeight = 64;
  static const double _scanSize = 56;
  static const double _scanOverhang = 22;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm + bottomInset,
      ),
      child: SizedBox(
        height: _barHeight + _scanOverhang,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.lifted,
              ),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history_rounded,
                    label: 'History',
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const SizedBox(width: _scanSize + 8),
                  _NavItem(
                    icon: Icons.eco_outlined,
                    activeIcon: Icons.eco_rounded,
                    label: 'Plants',
                    selected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: _barHeight - (_scanSize / 2) - 2,
              child: _ScanButton(onTap: onScanTap, size: _scanSize),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan a plant',
      child: Tooltip(
        message: 'Scan a plant',
        // The decoration lives on a plain Container, not an `Ink`: `Ink` paints
        // into the enclosing Material's layer and left a visible pale square
        // behind the button where it overlapped the white bar.
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.background, width: 3),
            boxShadow: AppShadows.lifted,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: const Icon(
                Icons.center_focus_strong_rounded,
                color: AppColors.onPrimary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                // The bar has a fixed height, so its labels are capped at 1.2x
                // while page content keeps scaling with the system setting.
                textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.2),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall
                    .withWeight(selected ? FontWeight.w600 : FontWeight.w500)
                    .copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
