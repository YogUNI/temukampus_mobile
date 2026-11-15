import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Kerangka bersama layar autentikasi (Masuk & Daftar).
///
/// Struktur: latar gradasi cobalt dengan pola tiket samar → header brand →
/// headline → kartu putih berisi formulir → footer.
///
/// Ritme vertikal sengaja memakai jarak tetap (bukan `Spacer`) agar posisi
/// elemen identik di semua tinggi layar.
class AuthShell extends StatelessWidget {
  final String headline;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final String? eyebrow;
  final VoidCallback? onBack;

  const AuthShell({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.child,
    this.footer,
    this.eyebrow,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: _AuthBackdrop(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol kembali menempel pada baris brand (kanan atas), bukan
                  // baris sendiri di atas logo: hemat satu baris tinggi dan
                  // sejajar dengan lockup brand.
                  Row(
                    children: [
                      const Expanded(child: _BrandRow()),
                      if (onBack != null) _BackButton(onTap: onBack!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  if (eyebrow != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppRadii.borderPill,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        eyebrow!,
                        style: AppTypography.micro.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  Text(
                    headline,
                    style: AppTypography.hero.copyWith(
                      fontSize: 25,
                      height: 1.18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.borderXl,
                      boxShadow: AppShadows.liftedCard,
                    ),
                    child: child,
                  ),

                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Center(child: footer!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Kembali',
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x59FFFFFF)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.borderSm,
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(2.5, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.confirmation_number_rounded,
            color: AppColors.cobalt,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TemuKampus',
              style: AppTypography.titleSmall.copyWith(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Universitas Mercu Buana',
              style: AppTypography.micro.copyWith(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Latar gradasi cobalt + pola tiket (memberi tekstur & kedalaman, bukan bidang datar).
class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.xl),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cobalt, AppColors.cobaltDark],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Kilau diagonal: memberi kesan permukaan kertas metalik.
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              height: 300,
              child: Transform.rotate(
                angle: -0.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Sorotan lembut di kanan atas
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // Cahaya hangat dari bawah supaya peralihan ke kartu putih terasa lembut.
            Positioned(
              bottom: -80,
              left: -40,
              right: -40,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.signal.withValues(alpha: 0.22),
                      AppColors.signal.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _TicketPatternPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pola tiket: outline, garis perforasi putus-putus, cekungan sobekan, dan
/// barcode tipis. Opasitas dinaikkan (0.09 → 0.18) supaya motifnya benar-benar
/// terbaca sebagai tiket, bukan noda samar.
class _TicketPatternPainter extends CustomPainter {
  void _ticket(
    Canvas canvas, {
    required Rect rect,
    required double rotation,
    required double alpha,
    bool withBarcode = true,
    double fillAlpha = 0.0,
    double strokeWidth = 1.3,
  }) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withValues(alpha: alpha);

    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: alpha * 0.8);

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(rotation);

    final r = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );
    final radius = Radius.circular(r.height * 0.16);
    final shape = RRect.fromRectAndRadius(r, radius);

    // Isian tipis: membuat bentuknya terbaca sebagai tiket, bukan sekadar garis.
    if (fillAlpha > 0) {
      canvas.drawRRect(
        shape,
        Paint()..color = Colors.white.withValues(alpha: fillAlpha),
      );
    }

    canvas.drawRRect(shape, stroke);

    // Garis perforasi vertikal + cekungan sobekan di ujung atas & bawah.
    final x = r.left + r.width * 0.66;
    for (double y = r.top + 10; y < r.bottom - 8; y += 9) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4.5), soft);
    }
    canvas.drawCircle(Offset(x, r.top), 4.5, stroke);
    canvas.drawCircle(Offset(x, r.bottom), 4.5, stroke);

    // Barcode tipis di sisi kiri (bagian "kode tiket").
    if (withBarcode) {
      final baseline = r.top + r.height * 0.72;
      var bx = r.left + r.width * 0.14;
      const widths = [1.2, 2.4, 1.0, 3.0, 1.4, 2.0, 1.0];
      for (var i = 0; i < widths.length; i++) {
        canvas.drawLine(
          Offset(bx, baseline),
          Offset(bx, baseline - r.height * 0.22),
          Paint()
            ..strokeWidth = widths[i]
            ..color = Colors.white.withValues(alpha: alpha * 0.9),
        );
        bx += widths[i] + 3.2;
      }
    }

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Tiket besar yang menjulur keluar dari tepi kiri atas.
    _ticket(
      canvas,
      rect: Rect.fromLTWH(-52, 34, 168, 96),
      rotation: 0.20,
      alpha: 0.22,
      fillAlpha: 0.04,
    );

    // Tiket utama di kanan atas — paling jelas, jadi wajah motif ini.
    _ticket(
      canvas,
      rect: Rect.fromLTWH(size.width - 168, 44, 178, 102),
      rotation: -0.16,
      alpha: 0.32,
      fillAlpha: 0.07,
      strokeWidth: 1.6,
    );

    // Dua tiket kecil sebagai irama di tengah.
    _ticket(
      canvas,
      rect: Rect.fromLTWH(size.width - 120, 178, 132, 78),
      rotation: 0.26,
      alpha: 0.22,
      fillAlpha: 0.03,
    );
    _ticket(
      canvas,
      rect: Rect.fromLTWH(-18, 196, 118, 70),
      rotation: -0.22,
      alpha: 0.18,
      fillAlpha: 0.03,
      withBarcode: false,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
