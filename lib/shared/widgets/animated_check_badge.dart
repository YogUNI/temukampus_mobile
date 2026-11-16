import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Lencana centang beranimasi: cincin berdenyut → centang tergambar bertahap,
/// dengan butiran konfeti yang menyebar lalu memudar.
///
/// Dipakai di konfirmasi pendaftaran acara, dan bisa dipakai ulang untuk
/// momen sukses lain. Animasi berjalan sekali (finite) — aman untuk tes.
class AnimatedCheckBadge extends StatefulWidget {
  /// Diameter cakram centang.
  final double size;

  /// Tampilkan konfeti di sekeliling lencana.
  final bool confetti;

  const AnimatedCheckBadge({
    super.key,
    this.size = 72,
    this.confetti = true,
  });

  @override
  State<AnimatedCheckBadge> createState() => _AnimatedCheckBadgeState();
}

class _AnimatedCheckBadgeState extends State<AnimatedCheckBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = widget.size * 1.6;
    final draw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    final ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    final confetti = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
    );

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.confetti)
            AnimatedBuilder(
              animation: confetti,
              builder: (context, _) => CustomPaint(
                size: Size(canvasSize, canvasSize),
                painter: _BadgeConfettiPainter(progress: confetti.value),
              ),
            ),
          AnimatedBuilder(
            animation: ring,
            builder: (context, _) => Container(
              width: widget.size + 26 * ring.value,
              height: widget.size + 26 * ring.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mintLight.withValues(
                  alpha: 0.55 * (1 - ring.value),
                ),
              ),
            ),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintLight,
              border: Border.all(color: AppColors.mint, width: 2),
            ),
            child: AnimatedBuilder(
              animation: draw,
              builder: (context, _) => CustomPaint(
                painter: _BadgeCheckPainter(progress: draw.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCheckPainter extends CustomPainter {
  final double progress;

  _BadgeCheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;
    final start = Offset(w * 0.28, h * 0.52);
    final mid = Offset(w * 0.44, h * 0.68);
    final end = Offset(w * 0.74, h * 0.34);
    const firstLeg = 0.42;

    final paint = Paint()
      ..color = AppColors.mintText
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(start.dx, start.dy);

    if (progress <= firstLeg) {
      final t = progress / firstLeg;
      path.lineTo(
        start.dx + (mid.dx - start.dx) * t,
        start.dy + (mid.dy - start.dy) * t,
      );
    } else {
      path.lineTo(mid.dx, mid.dy);
      final t = (progress - firstLeg) / (1 - firstLeg);
      path.lineTo(
        mid.dx + (end.dx - mid.dx) * t,
        mid.dy + (end.dy - mid.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BadgeCheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BadgeConfettiPainter extends CustomPainter {
  final double progress;

  _BadgeConfettiPainter({required this.progress});

  static const List<({double dx, double dy, double r, Color c})> _dots = [
    (dx: -0.44, dy: -0.30, r: 2.6, c: AppColors.signal),
    (dx: 0.42, dy: -0.36, r: 2.0, c: AppColors.cobalt),
    (dx: -0.50, dy: 0.12, r: 1.8, c: AppColors.cobalt),
    (dx: 0.48, dy: 0.18, r: 2.8, c: AppColors.signal),
    (dx: -0.22, dy: -0.46, r: 1.6, c: AppColors.mint),
    (dx: 0.16, dy: -0.48, r: 2.2, c: AppColors.signal),
    (dx: -0.32, dy: 0.40, r: 2.2, c: AppColors.mint),
    (dx: 0.32, dy: 0.42, r: 1.7, c: AppColors.cobalt),
    (dx: -0.06, dy: 0.48, r: 1.5, c: AppColors.signal),
    (dx: 0.06, dy: -0.44, r: 1.4, c: AppColors.cobalt),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final distance =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final spread = 0.5 + progress * 0.8;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint();

    for (final dot in _dots) {
      paint.color = dot.c.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(
        center + Offset(dot.dx * distance * spread, dot.dy * distance * spread),
        dot.r * (1 - progress * 0.35),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BadgeConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
