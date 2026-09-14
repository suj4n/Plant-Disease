import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Four rounded corner brackets marking where the leaf should sit.
///
/// Drawn rather than assembled from four positioned containers, so the stroke
/// stays crisp at any frame size.
class ScanFrameOverlay extends StatelessWidget {
  const ScanFrameOverlay({
    super.key,
    this.color = AppColors.onPrimary,
    this.strokeWidth = 3.5,
    this.cornerLength = 34,
    this.radius = 26,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _CornerBracketPainter(
          color: color,
          strokeWidth: strokeWidth,
          cornerLength: cornerLength,
          radius: radius,
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = radius;
    final len = cornerLength;

    final path = Path()
      // Top-left
      ..moveTo(0, r + len)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(r + len, 0)
      // Top-right
      ..moveTo(w - r - len, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, r + len)
      // Bottom-right
      ..moveTo(w, h - r - len)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(w - r - len, h)
      // Bottom-left
      ..moveTo(r + len, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, h - r - len);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.cornerLength != cornerLength ||
      old.radius != radius;
}

/// Sweeping line shown while the model is running.
class ScanSweepLine extends StatefulWidget {
  const ScanSweepLine({super.key, this.color = AppColors.onPrimary});

  final Color color;

  @override
  State<ScanSweepLine> createState() => _ScanSweepLineState();
}

class _ScanSweepLineState extends State<ScanSweepLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
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
    // The sweep is decorative; respect a reduced-motion preference.
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Align(
            alignment: Alignment(0, (_controller.value * 2) - 1),
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0),
                    widget.color.withValues(alpha: 0.9),
                    widget.color.withValues(alpha: 0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
