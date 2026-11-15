import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Durasi total animasi sukses (dipakai tes, jangan hardcode di tes).
const Duration kAuthSuccessDuration = Duration(milliseconds: 1500);

/// Tampilkan animasi sukses ber-brand, lalu jalankan [onCompleted].
///
/// Dipakai setelah "Masuk Sekarang" berhasil dan setelah pendaftaran akun
/// diterima, supaya perpindahan layar terasa disengaja — bukan lompatan.
Future<void> showAuthSuccessOverlay(
  BuildContext context, {
  required String title,
  required String message,
  String? footnote,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => AuthSuccessOverlay(
      title: title,
      message: message,
      footnote: footnote,
    ),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

/// Layar sukses: kartu tiket putih di atas gradasi cobalt, dengan centang yang
/// digambar bertahap, cincin berdenyut, dan butiran konfeti yang memudar.
class AuthSuccessOverlay extends StatefulWidget {
  final String title;
  final String message;
  final String? footnote;

  const AuthSuccessOverlay({
    super.key,
    required this.title,
    required this.message,
    this.footnote,
  });

  @override
  State<AuthSuccessOverlay> createState() => _AuthSuccessOverlayState();
}

class _AuthSuccessOverlayState extends State<AuthSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kAuthSuccessDuration,
    );

    _controller.forward().whenComplete(() {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOutBack),
    );
    final checkDraw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
    );
    final contentIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.78, curve: Curves.easeOut),
    );
    final confetti = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 1, curve: Curves.easeOutCubic),
    );

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cobalt, AppColors.cobaltDark],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: cardIn,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(cardIn),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.borderXl,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4012162B),
                        offset: Offset(0, 18),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 108,
                        height: 108,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Konfeti: butiran kecil yang menyebar lalu memudar.
                            AnimatedBuilder(
                              animation: confetti,
                              builder: (context, _) => CustomPaint(
                                size: const Size(108, 108),
                                painter: _ConfettiPainter(progress: confetti.value),
                              ),
                            ),
                            // Cincin berdenyut.
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final t = Curves.easeOut.transform(
                                  const Interval(0.1, 0.7)
                                      .transform(_controller.value),
                                );

                                return Container(
                                  width: 66 + 22 * t,
                                  height: 66 + 22 * t,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.mintLight
                                        .withValues(alpha: 0.55 * (1 - t)),
                                  ),
                                );
                              },
                            ),
                            // Cakram centang + centang yang digambar bertahap.
                            Container(
                              width: 66,
                              height: 66,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mintLight,
                              ),
                              child: AnimatedBuilder(
                                animation: checkDraw,
                                builder: (context, _) => CustomPaint(
                                  painter: _CheckPainter(
                                    progress: checkDraw.value,
                                    color: AppColors.mint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FadeTransition(
                        opacity: contentIn,
                        child: Column(
                          children: [
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.ink500,
                                height: 1.5,
                              ),
                            ),
                            if (widget.footnote != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cobaltLight,
                                  borderRadius: AppRadii.borderPill,
                                ),
                                child: Text(
                                  widget.footnote!,
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.cobalt,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centang yang tergambar dari 0..1 di sepanjang dua ruas garis.
class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;

    final start = Offset(w * 0.30, h * 0.52);
    final mid = Offset(w * 0.44, h * 0.66);
    final end = Offset(w * 0.72, h * 0.36);

    final firstLeg = 0.42;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
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
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Butiran konfeti: 10 titik di sudut tetap, menyebar + memudar seiring progres.
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static const List<({double dx, double dy, double r, Color c})> _dots = [
    (dx: -0.46, dy: -0.34, r: 2.6, c: AppColors.signal),
    (dx: 0.44, dy: -0.40, r: 2.0, c: AppColors.cobalt),
    (dx: -0.52, dy: 0.10, r: 1.8, c: AppColors.cobalt),
    (dx: 0.50, dy: 0.16, r: 2.8, c: AppColors.signal),
    (dx: -0.24, dy: -0.50, r: 1.6, c: AppColors.mint),
    (dx: 0.18, dy: -0.52, r: 2.2, c: AppColors.signal),
    (dx: -0.34, dy: 0.42, r: 2.2, c: AppColors.mint),
    (dx: 0.34, dy: 0.44, r: 1.7, c: AppColors.cobalt),
    (dx: -0.08, dy: 0.50, r: 1.5, c: AppColors.signal),
    (dx: 0.06, dy: -0.46, r: 1.4, c: AppColors.cobalt),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final spread = 0.55 + progress * 0.75;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint();

    for (final dot in _dots) {
      final distance = math.sqrt(size.width * size.width + size.height * size.height) / 2;
      paint.color = dot.c.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(
        center + Offset(dot.dx * distance * spread, dot.dy * distance * spread),
        dot.r * (1 - progress * 0.35),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
