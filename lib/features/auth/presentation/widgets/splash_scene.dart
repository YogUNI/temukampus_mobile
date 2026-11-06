import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';

/// Scene tiket 3D untuk splash.
///
/// Seluruh gerakan diturunkan dari satu [progress] (0→1) sehingga deterministik
/// dan berhenti sendiri (tanpa `repeat()`).
///
/// | rentang | gerakan |
/// |---------|---------|
/// | 0.00–0.12 | kamera dolly-in (1.14 → 1.0) |
/// | 0.02–0.34 | kartu berputar 3D (rotateY −1.05 → 0) |
/// | 0.24–0.44 | kartu mendarat (squash & stretch) |
/// | 0.16–0.42 | bentuk latar melayang masuk |
/// | 0.34–0.58 | chip muncul berurutan (elasticOut) |
/// | 0.30–0.56 | ledakan sparkle |
/// | 0.44–0.90 | idle float + bayangan tanah berdenyut |
///
/// Tata letak memakai kotak tetap [boxWidth]×[boxHeight] dengan posisi eksplisit
/// supaya komposisinya sama di layar sempit maupun lebar (tidak melayang-layang
/// mengikuti Alignment).
class SplashTicketScene extends StatelessWidget {
  final Animation<double> progress;

  /// Kotak scene. Kartu 210×136 selalu di tengah horizontal.
  static const double boxWidth = 380;
  static const double boxHeight = 296;

  static const double cardWidth = 210;
  static const double cardHeight = 136;

  /// Jarak kartu dari tepi atas kotak (menyisakan ruang untuk chip).
  static const double cardTop = 62;

  const SplashTicketScene({super.key, required this.progress});

  double _seg(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;

        // Kamera: masuk dari jauh. Exit ditangani pembungkus (lihat SplashScreen).
        final dolly =
            1.14 - 0.14 * Curves.easeOutCubic.transform(_seg(t, 0.0, 0.12));

        // Rotasi 3D kartu
        final flip = Curves.easeOutCubic.transform(_seg(t, 0.02, 0.34));
        final rotateY = -1.05 * (1 - flip);
        final rotateX = 0.18 * (1 - flip) + 0.04;

        // Squash & stretch saat mendarat
        final squash = math.sin(_seg(t, 0.24, 0.44) * math.pi) * 0.09;

        // Idle float: 1,5 siklus lembut setelah mendarat.
        final floatT = _seg(t, 0.44, 0.90);
        final bob = math.sin(floatT * math.pi * 3) * 5;
        final shadowScale = 1 - (bob.abs() / 5) * 0.22;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(rotateY)
          ..rotateX(rotateX);

        return Transform.scale(
          scale: dolly,
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Spotlight lembut: memberi "lantai" pada kartu.
                Positioned(
                  left: (boxWidth - 300) / 2,
                  top: 26,
                  child: _StageSpotlight(progress: _seg(t, 0.0, 0.30)),
                ),

                // Bentuk latar
                _DepthShapes(t: t, seg: _seg),

                // Bayangan tanah
                Positioned(
                  left: (boxWidth - 150) / 2,
                  top: cardTop + cardHeight - 8 - bob * 0.5,
                  child: Transform.scale(
                    scaleX: shadowScale,
                    child: _GroundShadow(
                      strength: 1 - (bob.abs() / 5) * 0.5,
                    ),
                  ),
                ),

                // Kartu tiket
                Positioned(
                  left: (boxWidth - cardWidth) / 2,
                  top: cardTop,
                  child: Transform.translate(
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
                ),

                // Ledakan sparkle (di belakang chip, di atas kartu)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparkBurstPainter(
                        progress: Curves.easeOutCubic
                            .transform(_seg(t, 0.30, 0.62)),
                        origin: Offset(
                          boxWidth / 2,
                          cardTop + cardHeight / 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Chip mengorbit — posisi eksplisit, tidak menabrak kartu.
                Positioned(
                  left: 8,
                  top: 16,
                  child: _OrbitChip(
                    label: 'Seminar',
                    icon: Icons.campaign_rounded,
                    background: AppColors.cobalt,
                    foreground: Colors.white,
                    appear: Curves.elasticOut.transform(_seg(t, 0.34, 0.56)),
                    drift: math.sin(floatT * math.pi * 3) * 2.5,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 16,
                  child: _OrbitChip(
                    label: '4 SKP',
                    icon: Icons.school_rounded,
                    background: AppColors.signalLight,
                    foreground: AppColors.ink,
                    appear: Curves.elasticOut.transform(_seg(t, 0.40, 0.62)),
                    drift: math.sin(floatT * math.pi * 3 + 1.4) * 2.5,
                  ),
                ),
                Positioned(
                  left: 30,
                  bottom: 14,
                  child: _OrbitChip(
                    label: 'Gratis',
                    icon: Icons.local_activity_rounded,
                    background: AppColors.mintLight,
                    foreground: AppColors.mintText,
                    appear: Curves.elasticOut.transform(_seg(t, 0.46, 0.68)),
                    drift: math.sin(floatT * math.pi * 3 + 2.8) * 2.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cahaya lembut di belakang kartu supaya tidak terlihat melayang di ruang kosong.
class _StageSpotlight extends StatelessWidget {
  final double progress;

  const _StageSpotlight({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.cobalt.withValues(alpha: 0.10),
              AppColors.cobalt.withValues(alpha: 0.03),
              AppColors.cobalt.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu tiket mini
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
                  width: 42,
                  height: 42,
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
                    size: 21,
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
                      _bar(width: 80, height: 8),
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
        final finder = (x < 3 && y < 3) ||
            (x > _modules - 4 && y < 3) ||
            (x < 3 && y > _modules - 4);
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
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, cell * 3, cell * 3),
        paint,
      );
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
  final double appear;
  final double drift;

  const _OrbitChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.appear,
    required this.drift,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, drift),
      child: Transform.scale(
        scale: appear.clamp(0.0, 1.2),
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
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
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
    );
  }
}

class _GroundShadow extends StatelessWidget {
  final double strength;

  const _GroundShadow({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: AppRadii.borderPill,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.20 * strength.clamp(0.3, 1)),
            blurRadius: 14,
            spreadRadius: 3,
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
    final a = Curves.easeOutCubic.transform(seg(t, 0.16, 0.42));
    final b = Curves.easeOutCubic.transform(seg(t, 0.22, 0.48));
    final c = Curves.easeOutCubic.transform(seg(t, 0.28, 0.54));

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 34 + (1 - a) * -26,
            left: 24 + (1 - a) * -24,
            child: Opacity(
              opacity: a * 0.9,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.cobaltLight,
                    borderRadius: AppRadii.borderLg,
                    border: Border.all(
                      color: AppColors.cobalt.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30 + (1 - b) * 26,
            right: 22 + (1 - b) * 24,
            child: Opacity(
              opacity: b * 0.9,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.signalLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.signal.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 96,
            right: 40,
            child: Opacity(
              opacity: c * 0.85,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: AppRadii.borderXs,
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.32),
                    ),
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

/// Ledakan sparkle: 14 percikan menyebar dari [origin] lalu memudar.
class _SparkBurstPainter extends CustomPainter {
  final double progress;
  final Offset origin;

  _SparkBurstPainter({required this.progress, required this.origin});

  static final List<_Spark> _sparks = List.generate(14, (i) {
    final angle = (i / 14) * math.pi * 2 + (i.isEven ? 0.22 : -0.18);
    final distance = 76 + (i % 4) * 14.0;
    final size = 2.0 + (i % 3);
    return _Spark(angle: angle, distance: distance, size: size);
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final spark in _sparks) {
      final distance = spark.distance * Curves.easeOut.transform(progress);
      final position = origin +
          Offset(
            math.cos(spark.angle) * distance,
            math.sin(spark.angle) * distance * 0.72,
          );
      final paint = Paint()
        ..color = (spark.size > 3 ? AppColors.signal : AppColors.cobalt)
            .withValues(alpha: 0.85 * fade);
      canvas.drawCircle(position, spark.size * (1 - progress * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}

class _Spark {
  final double angle;
  final double distance;
  final double size;

  const _Spark({
    required this.angle,
    required this.distance,
    required this.size,
  });
}