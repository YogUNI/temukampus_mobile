import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';

/// Scene tiket 3D untuk splash.
///
/// Semua gerakan diturunkan dari satu [progress] (0→1) sehingga timeline-nya
/// deterministik dan berhenti sendiri (tidak ada `repeat()`):
///
/// | rentang | gerakan |
/// |---------|---------|
/// | 0.00–0.12 | kamera dolly-in (scale 1.16 → 1.0) + fade masuk |
/// | 0.00–0.34 | kartu tiket berputar 3D (rotateY −1.15 → 0) |
/// | 0.22–0.40 | kartu mendarat: squash & stretch |
/// | 0.18–0.46 | bentuk latar melayang masuk dari tepi |
/// | 0.34–0.60 | chip mengorbit masuk (elasticOut, bertahap) |
/// | 0.30–0.62 | ledakan sparkle |
/// | 0.40–0.86 | idle float (bob sinus) + bayangan tanah berdenyut |
/// | 0.86–1.00 | exit: zoom-through (scale → 1.45) + fade |
class SplashTicketScene extends StatelessWidget {
  final Animation<double> progress;

  static const double cardWidth = 214;
  static const double cardHeight = 136;

  const SplashTicketScene({super.key, required this.progress});

  double _seg(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;

        // Kamera: masuk dari jauh, keluar menembus layar.
        final dolly = 1.16 - 0.16 * Curves.easeOutCubic.transform(_seg(t, 0.0, 0.12));
        final exitZoom = 1 + 0.45 * Curves.easeInCubic.transform(_seg(t, 0.86, 1.0));
        final sceneOpacity =
            Curves.easeOut.transform(_seg(t, 0.0, 0.10)) * (1 - _seg(t, 0.9, 1.0));

        // Rotasi 3D kartu
        final flip = Curves.easeOutCubic.transform(_seg(t, 0.0, 0.34));
        final rotateY = -1.15 * (1 - flip);
        final rotateX = 0.20 * (1 - flip) + 0.05;

        // Squash & stretch saat mendarat
        final land = _seg(t, 0.22, 0.40);
        final squash = math.sin(land * math.pi) * 0.10;

        // Idle float
        final floatT = _seg(t, 0.40, 0.86);
        final bob = math.sin(floatT * math.pi * 2) * 6;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(rotateY)
          ..rotateX(rotateX);

        return Opacity(
          opacity: sceneOpacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: dolly * exitZoom,
            child: SizedBox(
              width: 340,
              height: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bentuk latar (kedalaman)
                  _DepthShapes(t: t, seg: _seg),

                  // Bayangan tanah: makin dekat kartu, makin besar & gelap
                  Positioned(
                    bottom: 74 - bob * 0.6,
                    child: _GroundShadow(strength: 1 - (bob.abs() / 12).clamp(0, 0.6)),
                  ),

                  // Kartu tiket
                  Transform.translate(
                    offset: Offset(0, bob),
                    child: Transform(
                      transform: matrix,
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scaleX: 1 + squash,
                        scaleY: 1 - squash,
                        child: const _MiniTicket(),
                      ),
                    ),
                  ),

                  // Ledakan sparkle
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SparkBurstPainter(
                          progress: Curves.easeOutCubic.transform(_seg(t, 0.30, 0.66)),
                        ),
                      ),
                    ),
                  ),

                  // Chip mengorbit
                  _OrbitChip(
                    label: 'Seminar',
                    icon: Icons.campaign_rounded,
                    background: AppColors.cobalt,
                    foreground: Colors.white,
                    alignment: const Alignment(-1.02, -0.92),
                    appear: Curves.elasticOut.transform(_seg(t, 0.34, 0.56)),
                    drift: math.sin(floatT * math.pi * 2) * 3,
                  ),
                  _OrbitChip(
                    label: '4 SKP',
                    icon: Icons.school_rounded,
                    background: AppColors.signalLight,
                    foreground: AppColors.ink,
                    alignment: const Alignment(1.06, -0.36),
                    appear: Curves.elasticOut.transform(_seg(t, 0.40, 0.62)),
                    drift: math.sin(floatT * math.pi * 2 + 1.2) * 3,
                  ),
                  _OrbitChip(
                    label: 'Gratis',
                    icon: Icons.local_activity_rounded,
                    background: AppColors.mintLight,
                    foreground: AppColors.mintText,
                    alignment: const Alignment(-0.86, 0.72),
                    appear: Curves.elasticOut.transform(_seg(t, 0.46, 0.68)),
                    drift: math.sin(floatT * math.pi * 2 + 2.4) * 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu tiket mini (kartun 3D: border tegas + hard shadow)
// ---------------------------------------------------------------------------
class _MiniTicket extends StatelessWidget {
  const _MiniTicket();

  @override
  Widget build(BuildContext context) {
    return TicketContainer(
      width: SplashTicketScene.cardWidth,
      height: SplashTicketScene.cardHeight,
      punchRadius: 9,
      punchPositionPercent: 0.62,
      borderRadius: 20,
      borderColor: AppColors.ink,
      borderWidth: 1.8,
      hasShadow: true,
      shadowOffset: const Offset(6, 7),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.cobalt, AppColors.cobaltDark],
                    ),
                    borderRadius: AppRadii.borderSm,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEMINAR NASIONAL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                          fontSize: 7.5,
                          color: AppColors.cobalt,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _bar(width: null, height: 8),
                      const SizedBox(height: AppSpacing.xxs),
                      _bar(width: 84, height: 8),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: AppRadii.borderXs,
                  ),
                  child: Text(
                    'Rp 25.000',
                    style: AppTypography.micro.copyWith(
                      fontSize: 9.5,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                const _MiniQr(size: 30),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.cobalt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ink200,
        borderRadius: AppRadii.borderXs,
      ),
    );
  }
}

class _MiniQr extends StatelessWidget {
  final double size;

  const _MiniQr({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.borderXs,
        border: Border.all(color: AppColors.ink200),
      ),
      child: CustomPaint(painter: _MiniQrPainter()),
    );
  }
}

class _MiniQrPainter extends CustomPainter {
  static const int _modules = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = AppColors.ink;
    for (var y = 0; y < _modules; y++) {
      for (var x = 0; x < _modules; x++) {
        final finder = (x < 3 && y < 3) || (x > _modules - 4 && y < 3) || (x < 3 && y > _modules - 4);
        if (finder) continue;
        if ((x * 5 + y * 7 + x * y) % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
    for (final offset in [
      const Offset(0, 0),
      Offset(cell * (_modules - 3), 0),
      Offset(0, cell * (_modules - 3)),
    ]) {
      canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, cell * 3, cell * 3), paint);
      canvas.drawRect(
        Rect.fromLTWH(offset.dx + cell, offset.dy + cell, cell, cell),
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Elemen pendukung scene
// ---------------------------------------------------------------------------
class _OrbitChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Alignment alignment;
  final double appear;
  final double drift;

  const _OrbitChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.alignment,
    required this.appear,
    required this.drift,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(0, drift),
        child: Transform.scale(
          scale: appear.clamp(0.0, 1.6),
          child: Opacity(
            opacity: appear.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadii.borderPill,
                border: Border.all(color: AppColors.ink, width: 1.4),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(2, 2), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: foreground),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTypography.micro.copyWith(
                      fontSize: 9.5,
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroundShadow extends StatelessWidget {
  final double strength;

  const _GroundShadow({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: AppRadii.borderPill,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22 * strength.clamp(0.2, 1)),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _DepthShapes extends StatelessWidget {
  final double t;
  final double Function(double, double, double) seg;

  const _DepthShapes({required this.t, required this.seg});

  @override
  Widget build(BuildContext context) {
    final a = Curves.easeOutCubic.transform(seg(t, 0.18, 0.46));
    final b = Curves.easeOutCubic.transform(seg(t, 0.24, 0.52));
    final c = Curves.easeOutCubic.transform(seg(t, 0.30, 0.58));

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 24 + (1 - a) * -40,
            left: 18 + (1 - a) * -30,
            child: Opacity(
              opacity: a,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.cobaltLight,
                    borderRadius: AppRadii.borderLg,
                    border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.25)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 34 + (1 - b) * 40,
            right: 14 + (1 - b) * 30,
            child: Opacity(
              opacity: b,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.signalLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.signal.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 44,
            right: 34,
            child: Opacity(
              opacity: c * 0.9,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: AppRadii.borderXs,
                    border: Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ledakan sparkle: 14 percikan menyebar dari pusat lalu memudar.
class _SparkBurstPainter extends CustomPainter {
  final double progress;

  _SparkBurstPainter({required this.progress});

  static final List<_Spark> _sparks = List.generate(14, (i) {
    final angle = (i / 14) * math.pi * 2 + (i.isEven ? 0.22 : -0.18);
    final distance = 70 + (i % 4) * 16.0;
    final size = 2.0 + (i % 3);
    return _Spark(angle: angle, distance: distance, size: size);
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2 - 6);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final spark in _sparks) {
      final distance = spark.distance * Curves.easeOut.transform(progress);
      final position = center +
          Offset(math.cos(spark.angle) * distance, math.sin(spark.angle) * distance);
      final paint = Paint()
        ..color = (spark.size > 3 ? AppColors.signal : AppColors.cobalt)
            .withValues(alpha: 0.85 * fade);
      canvas.drawCircle(position, spark.size * (1 - progress * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Spark {
  final double angle;
  final double distance;
  final double size;

  const _Spark({required this.angle, required this.distance, required this.size});
}