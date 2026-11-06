import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
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
                  // Penyelenggara & Format Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      const SizedBox(width: 8),
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
                    style: AppTypography.titleMedium.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 10),

                  // Badges: SKP, Sertifikat, Kuota Menipis
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (event.hasSkp)
                        _buildChip(
                          '${event.skpPoints} SKP',
                          AppColors.cobalt,
                          AppColors.cobaltLight,
                        ),
                      if (event.hasCertificate)
                        _buildChip(
                          'Sertifikat',
                          AppColors.mintText,
                          AppColors.mintLight,
                        ),
                      if (event.isFull)
                        _buildChip(
                          'Kuota Penuh',
                          AppColors.dangerText,
                          AppColors.dangerLight,
                        )
                      else if (event.isQuotaAlmostFull)
                        _buildChip(
                          'Sisa ${event.remainingQuota} tiket!',
                          AppColors.ink,
                          AppColors.signalLight,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Garis Sobekan Putus-Putus
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: DottedTearLine(color: AppColors.ink200),
            ),

            // Stub Sobekan Tiket Bagian Bawah
            Container(
              color: AppColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HARGA TIKET',
                        style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.ink400),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        event.isFree ? 'Gratis' : event.formattedPrice,
                        style: AppTypography.numericCode.copyWith(
                          fontSize: 15,
                          color: event.isFree ? AppColors.mintText : AppColors.cobalt,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Lihat Detail',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.cobalt, size: 14),
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

  Widget _buildChip(String text, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.badge.copyWith(color: textCol, fontSize: 10),
      ),
    );
  }
}
