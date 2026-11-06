import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Ilustrasi onboarding — dibangun dari widget (tanpa aset gambar) supaya
/// tetap tajam di semua DPI dan warnanya selalu sinkron dengan token brand.
class OnboardingIllustration extends StatelessWidget {
  final int index;

  const OnboardingIllustration({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236,
      child: switch (index) {
        0 => const _CatalogScene(),
        1 => const _IdentityScene(),
        _ => const _TicketScene(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Scene 1 — katalog acara
// ---------------------------------------------------------------------------
class _CatalogScene extends StatelessWidget {
  const _CatalogScene();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Kartu belakang
        Transform.translate(
          offset: const Offset(26, -22),
          child: Transform.rotate(
            angle: -0.10,
            child: _MiniEventCard(
              width: 150,
              accent: AppColors.signalLight,
              accentIcon: Icons.music_note_rounded,
              accentColor: AppColors.signal,
              titleLines: const [1.0, 0.55],
              priceLabel: 'Gratis',
              priceColor: AppColors.mintText,
            ),
          ),
        ),
        // Kartu depan
        Transform.translate(
          offset: const Offset(-18, 26),
          child: Transform.rotate(
            angle: 0.05,
            child: _MiniEventCard(
              width: 176,
              accent: AppColors.cobaltLight,
              accentIcon: Icons.computer_rounded,
              accentColor: AppColors.cobalt,
              titleLines: const [1.0, 0.72],
              priceLabel: 'Rp 25.000',
              priceColor: AppColors.ink,
            ),
          ),
        ),
        // Chip melayang
        Positioned(
          top: 8,
          left: 6,
          child: _FloatingChip(
            label: '4 SKP',
            background: AppColors.cobalt,
            foreground: Colors.white,
          ),
        ),
        Positioned(
          bottom: 6,
          right: 4,
          child: _FloatingChip(
            label: 'Terverifikasi',
            background: AppColors.mintLight,
            foreground: AppColors.mintText,
            icon: Icons.verified_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniEventCard extends StatelessWidget {
  final double width;
  final Color accent;
  final IconData accentIcon;
  final Color accentColor;
  final List<double> titleLines;
  final String priceLabel;
  final Color priceColor;

  const _MiniEventCard({
    required this.width,
    required this.accent,
    required this.accentIcon,
    required this.accentColor,
    required this.titleLines,
    required this.priceLabel,
    required this.priceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink100),
        boxShadow: AppShadows.liftedCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: AppRadii.borderSm,
            ),
            child: Center(child: Icon(accentIcon, color: accentColor, size: 26)),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final factor in titleLines) ...[
            FractionallySizedBox(
              widthFactor: factor,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.ink100,
                  borderRadius: AppRadii.borderXs,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Text(
                priceLabel,
                style: AppTypography.micro.copyWith(
                  fontSize: 9.5,
                  color: priceColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.cobalt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scene 2 — kartu identitas mahasiswa
// ---------------------------------------------------------------------------
class _IdentityScene extends StatelessWidget {
  const _IdentityScene();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Kartu ID
        Transform.rotate(
          angle: -0.03,
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.ink100),
              boxShadow: AppShadows.liftedCard,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.cobaltLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.cobalt,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 9,
                            width: 96,
                            decoration: BoxDecoration(
                              color: AppColors.ink200,
                              borderRadius: AppRadii.borderXs,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            height: 7,
                            width: 64,
                            decoration: BoxDecoration(
                              color: AppColors.ink100,
                              borderRadius: AppRadii.borderXs,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: AppRadii.borderXs,
                      ),
                      child: Text(
                        'UMB',
                        style: AppTypography.micro.copyWith(
                          fontSize: 8.5,
                          color: AppColors.mintText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: AppRadii.borderSm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'NIM',
                        style: AppTypography.micro.copyWith(
                          fontSize: 8.5,
                          color: AppColors.ink400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '41524010001',
                            style: AppTypography.numericCode.copyWith(
                              fontSize: 15,
                              color: AppColors.ink,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Badge terverifikasi
        Positioned(
          right: 6,
          bottom: 18,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 3),
              boxShadow: AppShadows.softCard,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
          ),
        ),
        Positioned(
          left: 10,
          top: 14,
          child: _FloatingChip(
            label: 'Otomatis terisi',
            background: AppColors.cobaltLight,
            foreground: AppColors.cobalt,
            icon: Icons.bolt_rounded,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scene 3 — tiket QR
// ---------------------------------------------------------------------------
class _TicketScene extends StatelessWidget {
  const _TicketScene();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.04,
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderLg,
              border: Border.all(color: AppColors.ink, width: 1.4),
              boxShadow: AppShadows.liftedCard,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'TEMUKAMPUS PASS',
                      style: AppTypography.micro.copyWith(
                        fontSize: 8.5,
                        color: AppColors.cobalt,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: AppRadii.borderXs,
                      ),
                      child: Text(
                        'H-3',
                        style: AppTypography.micro.copyWith(
                          fontSize: 8,
                          color: AppColors.mintText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.borderSm,
                    border: Border.all(color: AppColors.ink200),
                  ),
                  child: CustomPaint(
                    size: const Size(84, 84),
                    painter: _FakeQrPainter(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'TK-7F3KQ9',
                  style: AppTypography.numericCode.copyWith(
                    fontSize: 13,
                    color: AppColors.cobalt,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 8,
          child: Transform.rotate(
            angle: -0.14,
            child: _FloatingChip(
              label: 'TERKONFIRMASI',
              background: AppColors.mintLight,
              foreground: AppColors.mintText,
              icon: Icons.check_circle_rounded,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 4,
          child: _FloatingChip(
            label: 'Scan sekali',
            background: AppColors.signalLight,
            foreground: AppColors.ink,
            icon: Icons.qr_code_scanner_rounded,
          ),
        ),
      ],
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _FloatingChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.borderPill,
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.micro.copyWith(
                fontSize: 9,
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pola mirip QR (deterministik) untuk ilustrasi — bukan QR sungguhan.
class _FakeQrPainter extends CustomPainter {
  static const int _modules = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _modules;
    final paint = Paint()..color = AppColors.ink;

    for (var y = 0; y < _modules; y++) {
      for (var x = 0; x < _modules; x++) {
        final isFinder = (x < 7 && y < 7) ||
            (x > _modules - 8 && y < 7) ||
            (x < 7 && y > _modules - 8);
        if (isFinder) continue;
        // Pola pseudo-acak stabil: hash sederhana dari koordinat.
        if ((x * 7 + y * 13 + x * y) % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint,
          );
        }
      }
    }

    // Tiga finder pattern
    void finder(double left, double top) {
      final outer = Rect.fromLTWH(left, top, cell * 7, cell * 7);
      canvas.drawRect(outer, Paint()..color = AppColors.ink);
      canvas.drawRect(
        Rect.fromLTWH(left + cell, top + cell, cell * 5, cell * 5),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(left + cell * 2, top + cell * 2, cell * 3, cell * 3),
        Paint()..color = AppColors.ink,
      );
    }

    finder(0, 0);
    finder(cell * (_modules - 7), 0);
    finder(0, cell * (_modules - 7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}