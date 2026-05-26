import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular Progress Ring - For health scores and countdowns
class CircularProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? child;

  const CircularProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.progressColor,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              progressColor: progressColor ?? AppColors.primary,
              backgroundColor: backgroundColor ?? AppColors.cardElevated,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Health Score Circle with number display
class HealthScoreCircle extends StatelessWidget {
  final int score;
  final double size;
  final String? label;

  const HealthScoreCircle({
    super.key,
    required this.score,
    this.size = 80,
    this.label,
  });

  Color get _color {
    if (score >= 80) return AppColors.emerald;
    if (score >= 60) return AppColors.amber;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return CircularProgressRing(
      progress: score / 100,
      size: size,
      progressColor: _color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: AppTextStyles.headlineMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (label != null)
            Text(
              label!,
              style: AppTextStyles.labelSmall,
            ),
        ],
      ),
    );
  }
}

/// Days Countdown Ring
class DaysCountdownRing extends StatelessWidget {
  final int daysRemaining;
  final int totalDays;
  final double size;

  const DaysCountdownRing({
    super.key,
    required this.daysRemaining,
    required this.totalDays,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalDays - daysRemaining) / totalDays;
    
    return CircularProgressRing(
      progress: progress,
      size: size,
      progressColor: AppColors.primary,
      strokeWidth: 6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$daysRemaining',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Days',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Stage Progress Indicator (Seeding -> Sprout -> Maturity -> Harvest)
class StageProgressIndicator extends StatelessWidget {
  final int currentStage; // 0-3
  final List<String> stages;

  const StageProgressIndicator({
    super.key,
    required this.currentStage,
    this.stages = const ['Seeding', 'Sprout', 'Maturity', 'Harvest'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(stages.length, (index) {
        final isActive = index <= currentStage;
        final isCurrent = index == currentStage;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.primary : AppColors.muted,
                border: isCurrent
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              stages[index],
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.foreground : AppColors.muted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
