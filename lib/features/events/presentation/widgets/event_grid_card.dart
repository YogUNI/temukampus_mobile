import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/event_model.dart';

/// Kartu Acara Grid 2-Kolom Modern (Inspirasi: 9 Art Store & Oakory).
class EventGridCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventGridCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLowQuota = event.remainingQuota != null && event.remainingQuota! <= 10 && event.remainingQuota! > 0;

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink100, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C12162B),
              offset: Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Poster Gambar dengan Floating Badges
            Stack(
              children: [
                AppNetworkOrAssetImage(
                  imagePath: event.posterUrl,
                  height: 118,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Gradient scrim agar badge selalu terbaca jelas
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Badge Kiri Atas: Format & SKP
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.format.toUpperCase(),
                          style: AppTypography.badge.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (event.skpPoints > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cobalt,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${event.skpPoints} SKP',
                            style: AppTypography.badge.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Floating Warning Kuota Kanan Atas
                if (isLowQuota)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.signal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sisa ${event.remainingQuota}!',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Konten Informasi Acara
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Penyelenggara
                  Text(
                    event.organization.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.cobalt,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Judul Acara (2 Baris)
                  SizedBox(
                    height: 38,
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tanggal Acara
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.ink400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppFormatters.eventDate(event.startAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.ink500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Harga & Tombol Aksi Panah (↗)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIKET',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 8.5,
                              color: AppColors.ink400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            event.formattedPrice,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: event.isPaid ? AppColors.cobalt : AppColors.mintText,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

