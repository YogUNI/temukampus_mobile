import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/event_model.dart';

/// Kartu jadwal berbentuk tiket fisik (notch kiri-kanan + perforasi).
///
/// Geometri dijaga simetris: dua baris [rowHeight] + padding [AppSpacing.lg],
/// sehingga garis perforasi tepat berada di tengah (50%) — posisi lubang notch.
/// Asersi geometri ada di `event_detail_layout_test.dart`.
class EventTicketInfoCard extends StatelessWidget {
  final EventModel event;

  static const double rowHeight = 64;

  const EventTicketInfoCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return TicketContainer(
      punchRadius: 12,
      punchPositionPercent: 0.5,
      borderRadius: 16,
      borderColor: AppColors.ink200,
      borderWidth: 1.2,
      hasShadow: true,
      shadowOffset: const Offset(2.5, 2.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  const _IconBadge(
                    icon: Icons.calendar_month_rounded,
                    background: AppColors.cobaltLight,
                    foreground: AppColors.cobalt,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal & Waktu',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.ink400,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          AppFormatters.eventDate(event.startAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          AppFormatters.eventTimeRange(event.startAt, event.endAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11.5,
                            color: AppColors.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DottedTearLine(color: AppColors.ink200),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  const _IconBadge(
                    icon: Icons.location_on_rounded,
                    background: AppColors.signalLight,
                    foreground: AppColors.signal,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.ink400,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          event.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Tag format dibatasi lebarnya agar tidak "mencuri" ruang
                  // kolom teks lokasi (cek overflow di event_detail_layout_test).
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 104),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink100,
                        borderRadius: AppRadii.borderXs,
                      ),
                      child: Text(
                        event.formatLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                          color: AppColors.ink700,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _IconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.borderSm,
      ),
      child: Icon(icon, color: foreground, size: 20),
    );
  }
}