import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/ticket_model.dart';
import 'ticket_countdown.dart';

/// Kartu tiket premium untuk daftar "Tiket Saya".
///
/// Tinggi blok utama & stub dipaku supaya garis perforasi sejajar dengan lubang
/// notch di posisi [punchPositionPercent]. Asersi geometri ada di
/// `ticket_visual_test.dart`.
class TicketListCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  static const double mainPadding = 14;
  static const double mainBlockHeight = 88;
  static const double stubHeight = 52;
  static const double punchPositionPercent = 0.685;

  const TicketListCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  RegistrationStatusType get _statusType {
    switch (ticket.status) {
      case 'confirmed':
        return RegistrationStatusType.confirmed;
      case 'needs_revision':
        return RegistrationStatusType.needsRevision;
      case 'cancelled':
        return RegistrationStatusType.cancelled;
      case 'rejected':
        return RegistrationStatusType.rejected;
      case 'pending_verification':
      default:
        return RegistrationStatusType.pendingVerification;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: TicketContainer(
        punchRadius: 11,
        punchPositionPercent: punchPositionPercent,
        borderRadius: 18,
        borderColor: AppColors.ink,
        borderWidth: 1.4,
        hasShadow: true,
        shadowOffset: const Offset(3, 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === BLOK UTAMA ===
            Padding(
              padding: const EdgeInsets.all(mainPadding),
              child: SizedBox(
                height: mainBlockHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadii.borderSm,
                      child: SizedBox(
                        // 4:5 — rasio master poster backend (1080×1350).
                        width: 52,
                        height: 64,
                        child: ticket.event.posterUrl != null
                            ? AppNetworkOrAssetImage(
                                imagePath: ticket.event.posterUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.cobaltLight,
                                child: const Icon(
                                  Icons.event_rounded,
                                  color: AppColors.cobalt,
                                  size: 26,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 11, color: AppColors.ink400),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  '${AppFormatters.eventDate(ticket.event.startAt)} · '
                                  '${AppFormatters.eventTime(ticket.event.startAt)}',
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 11, color: AppColors.ink400),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  ticket.event.location,
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
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TicketCountdownChip(startAt: ticket.event.startAt),
                  ],
                ),
              ),
            ),

            // === PERFORASI ===
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DottedTearLine(color: AppColors.ink200),
            ),

            // === STUB: KODE + STATUS + AKSI ===
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SizedBox(
                height: stubHeight - AppSpacing.lg,
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KODE TIKET',
                          style: AppTypography.micro.copyWith(
                            fontSize: 8.5,
                            color: AppColors.ink400,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          ticket.ticketCode,
                          maxLines: 1,
                          style: AppTypography.numericCode.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cobalt,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Flexible(
                      child: StatusPill(status: _statusType),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.cobalt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}