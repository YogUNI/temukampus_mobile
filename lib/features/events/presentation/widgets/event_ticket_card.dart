import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/event_model.dart';

class EventTicketCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventTicketCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TicketContainer(
        punchRadius: 12.0,
        punchPositionPercent: 0.72,
        borderRadius: 16.0,
        borderColor: AppColors.ink,
        borderWidth: 1.4,
        hasShadow: true,
        shadowOffset: const Offset(3, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Utama Atas Tiket
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Penyelenggara & Format Badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.organization.name,
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.cobalt,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.ink100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event.format.toUpperCase(),
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.ink700,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Judul Acara
                            Text(
                              event.title,
                              style: AppTypography.titleMedium.copyWith(fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (event.posterUrl != null) ...[
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppNetworkOrAssetImage(
                            imagePath: event.posterUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Jadwal & Lokasi
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.ink500),
                      const SizedBox(width: 6),
                      Text(
                        AppFormatters.eventDate(event.startAt),
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.ink500),
                      const SizedBox(width: 4),
                      Text(
                        AppFormatters.eventTime(event.startAt),
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.ink500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          style: AppTypography.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Badges: SKP, Sertifikat, Kuota
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (event.skpPoints > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cobaltLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${event.skpPoints} SKP',
                            style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10),
                          ),
                        ),
                      if (event.hasCertificate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.mintLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Sertifikat',
                            style: AppTypography.badge.copyWith(color: AppColors.mintText, fontSize: 10),
                          ),
                        ),
                      if (event.remainingQuota != null && event.remainingQuota! <= 10 && event.remainingQuota! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.signalLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sisa ${event.remainingQuota} tiket!',
                            style: AppTypography.badge.copyWith(color: AppColors.ink, fontSize: 10),
                          ),
                        ),
                      if (event.isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.ink200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Kuota Penuh',
                            style: AppTypography.badge.copyWith(color: AppColors.ink500, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Garis Sobekan Putus-Putus
            const DottedTearLine(
              dashWidth: 5,
              dashSpace: 4,
              height: 1.2,
              color: AppColors.ink200,
            ),

            // Bagian Bawah Tiket (Harga & CTA)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HARGA TIKET',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: AppColors.ink500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.formattedPrice,
                        style: AppTypography.hero.copyWith(
                          fontSize: 16,
                          color: event.isPaid ? AppColors.cobalt : AppColors.mintText,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Lihat Detail',
                        style: AppTypography.label.copyWith(color: AppColors.cobalt, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.cobalt),
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
