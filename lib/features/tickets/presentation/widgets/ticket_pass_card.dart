import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/ticket_model.dart';
import 'ticket_countdown.dart';

/// Kartu "Temukampus Pass": QR tajam, stempel status miring, dan rincian acara.
///
/// QR dirender 220pt dengan koreksi galat tinggi dan modul persegi tanpa celah
/// supaya tetap terbaca oleh kamera panitia di layar redup.
class TicketPassCard extends StatelessWidget {
  final TicketModel ticket;
  final RegistrationStatusType statusType;
  final VoidCallback onCopyCode;

  static const double qrSize = 220;

  const TicketPassCard({
    super.key,
    required this.ticket,
    required this.statusType,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderXl,
        border: Border.all(color: AppColors.ink, width: 1.6),
        boxShadow: AppShadows.liftedCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // === HEADER: BRAND + HARI-H + STEMPEL ===
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'TEMUKAMPUS PASS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.micro.copyWith(
                      color: AppColors.cobalt,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TicketCountdownChip(startAt: ticket.event.startAt),
                const Spacer(),
                // FittedBox menjaga stempel tetap utuh tanpa memaksa baris meluber.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: StatusPill(status: statusType, isStamp: true),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: DottedTearLine(color: AppColors.ink100),
          ),

          // === QR ===
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.borderMd,
                border: Border.all(color: AppColors.ink, width: 1.6),
              ),
              child: QrImageView(
                data: ticket.ticketCode,
                version: QrVersions.auto,
                size: qrSize,
                gapless: true,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),

          // === KODE TIKET ===
          GestureDetector(
            onTap: () {
              AppHaptics.selection();
              onCopyCode();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ticket.ticketCode,
                    style: AppTypography.numericCode.copyWith(
                      fontSize: 22,
                      letterSpacing: 2.4,
                      color: AppColors.cobalt,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.ink500),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // === PETUNJUK HARI-H ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: ticket.isCheckedIn ? AppColors.mintLight : AppColors.paper,
                borderRadius: AppRadii.borderSm,
                border: Border.all(
                  color: ticket.isCheckedIn ? AppColors.mint : AppColors.ink100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ticket.isCheckedIn
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: ticket.isCheckedIn ? AppColors.mintText : AppColors.ink500,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ticket.isCheckedIn
                          ? 'Presensi masuk berhasil: ${AppFormatters.eventTime(ticket.checkedInAt!)}'
                          : 'Tunjukkan QR ini ke panitia di meja registrasi saat hari-H. '
                              'Naikkan kecerahan layar agar mudah dipindai.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: ticket.isCheckedIn
                            ? AppColors.mintText
                            : AppColors.ink700,
                        fontWeight:
                            ticket.isCheckedIn ? FontWeight.w700 : FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: DottedTearLine(color: AppColors.ink200),
          ),

          // === RINCIAN ACARA & PESERTA ===
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ticket.event.posterUrl != null) ...[
                      ClipRRect(
                        borderRadius: AppRadii.borderSm,
                        child: AppNetworkOrAssetImage(
                          imagePath: ticket.event.posterUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Text(
                        ticket.event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(fontSize: 15.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${AppFormatters.eventDate(ticket.event.startAt)} · '
                      '${AppFormatters.eventTimeRange(ticket.event.startAt, ticket.event.endAt)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                _MetaRow(
                  icon: Icons.location_on_rounded,
                  text: ticket.event.location,
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.ink100),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NAMA PESERTA',
                            style: AppTypography.micro.copyWith(
                              fontSize: 8.5,
                              color: AppColors.ink400,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            ticket.participant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NIM',
                          style: AppTypography.micro.copyWith(
                            fontSize: 8.5,
                            color: AppColors.ink400,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          ticket.participant.nim ?? '-',
                          style: AppTypography.numericCode.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.cobalt),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}