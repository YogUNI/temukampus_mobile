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
                  if (onBack != null) ...[
                    _BackButton(onTap: onBack!),
                    const SizedBox(height: AppSpacing.lg),
                  ] else
                    const SizedBox(height: AppSpacing.sm),

                  const _BrandRow(),
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

/// Latar gradasi cobalt + pola tiket samar (memberi tekstur, bukan bidang datar).
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
            // Sorotan lembut di kanan atas
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
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

/// Pola garis tiket (outline + perforasi) yang sangat samar.
class _TicketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.09);

    void ticket(Rect rect, double rotation) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(rotation);
      final r = Rect.fromCenter(
        center: Offset.zero,
        width: rect.width,
        height: rect.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(14)),
        stroke,
      );
      // garis perforasi vertikal
      final x = r.left + r.width * 0.68;
      for (double y = r.top + 8; y < r.bottom - 6; y += 8) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 4), stroke);
      }
      canvas.restore();
    }

    ticket(Rect.fromLTWH(size.width - 150, 22, 150, 86), -0.22);
    ticket(Rect.fromLTWH(-40, 120, 128, 74), 0.16);
    ticket(Rect.fromLTWH(size.width - 96, 190, 130, 78), 0.28);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
