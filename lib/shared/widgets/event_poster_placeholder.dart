import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Placeholder poster acara yang tetap "ber-brand" ketika penyelenggara belum
/// mengunggah poster (data nyata sering begitu, sedangkan data contoh selalu
/// punya gambar).
///
/// Komposisi: gradien lembut cobalt→signal, motif perforasi tiket, ikon
/// kategori di dalam chip putih, dan label kategori. Tidak ada teks putih di
/// atas Signal Orange — aturan keras brand tetap dipatuhi.
class EventPosterPlaceholder extends StatelessWidget {
  const EventPosterPlaceholder({
    super.key,
    this.categorySlug,
    this.categoryName,
    this.title,
    this.compact = false,
  });

  final String? categorySlug;
  final String? categoryName;
  final String? title;

  /// Versi kecil untuk thumbnail (tiket, ringkasan) — ikon lebih kecil,
  /// label kategori disembunyikan.
  final bool compact;

  static const Map<String, IconData> _icons = {
    'seminar': Icons.co_present_rounded,
    'workshop': Icons.build_circle_rounded,
    'pelatihan': Icons.school_rounded,
    'lomba': Icons.emoji_events_rounded,
    'olahraga': Icons.sports_soccer_rounded,
    'seni-budaya': Icons.palette_rounded,
    'rekrutmen-kepanitiaan': Icons.groups_rounded,
    'sosial': Icons.volunteer_activism_rounded,
    'lainnya': Icons.event_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final slug = (categorySlug ?? 'lainnya').toLowerCase();
    final icon = _icons[slug] ?? _icons['lainnya']!;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cobaltLight, AppColors.signalLight, AppColors.paper],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Motif perforasi tiket (dua lajur titik samar).
          CustomPaint(painter: _PerforationPainter()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 34 : 52,
                  height: compact ? 34 : 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(compact ? 11 : 16),
                    border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.18)),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 18 : 26,
                    color: AppColors.cobalt,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      (categoryName ?? 'Acara Kampus').toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.ink,
                        letterSpacing: 1.4,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Titik-titik perforasi diagonal sebagai penanda motif tiket.
class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cobalt.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    const step = 14.0;
    const radius = 1.6;

    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        // Selang-seling agar terlihat seperti perforasi, bukan grid penuh.
        if (((x / step).round() + (y / step).round()).isEven) continue;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
