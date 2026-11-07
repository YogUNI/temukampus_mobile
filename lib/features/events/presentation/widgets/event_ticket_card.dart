import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/event_model.dart';

/// Kartu acara mode daftar (vertikal) di Jelajah.
///
/// Sedikit lebih padat daripada kartu grid: poster mini kiri, meta kanan,
/// baris harga + aksi di bawah. Elevasi soft, sama dengan [EventGridCard].
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
    final isLowQuota = event.remainingQuota != null &&
        event.remainingQuota! <= 10 &&
        event.remainingQuota! > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink100),
        boxShadow: AppShadows.softCard,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.borderMd,
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              onTap();
            },
            splashColor: AppColors.cobalt.withValues(alpha: 0.06),
            highlightColor: AppColors.cobalt.withValues(alpha: 0.03),
            child: Padding(
              padding: AppSpacing.cardCompact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadii.borderSm,
                        child: SizedBox(
                          // 4:5 — rasio master poster (1080×1350), bukan kotak.
                          width: 72,
                          height: 90,
                          child: event.posterUrl != null
                              ? AppNetworkOrAssetImage(
                                  imagePath: event.posterUrl,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppColors.cobaltLight,
                                  child: const Icon(
                                    Icons.event_rounded,
                                    color: AppColors.cobalt,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SizedBox(
                          height: 92,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.organization.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.micro.copyWith(
                                  color: AppColors.cobalt,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 12, color: AppColors.ink400),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      '${AppFormatters.eventDate(event.startAt)} · ${AppFormatters.eventTime(event.startAt)}',
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
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: AppColors.ink400),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.ink500,
                          ),
                        ),
                      ),
                      if (event.skpPoints > 0)
                        _MiniTag(
                          label: '${event.skpPoints} SKP',
                          background: AppColors.cobaltLight,
                          foreground: AppColors.cobalt,
                        ),
                      if (event.hasCertificate) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _MiniTag(
                          label: 'Sertifikat',
                          background: AppColors.mintLight,
                          foreground: AppColors.mintText,
                        ),
                      ],
                      if (isLowQuota) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _MiniTag(
                          label: 'Sisa ${event.remainingQuota}',
                          background: AppColors.signalLight,
                          foreground: AppColors.ink,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.ink100),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HARGA TIKET',
                              style: AppTypography.micro.copyWith(
                                fontSize: 8.5,
                                color: AppColors.ink400,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              event.formattedPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: event.isPaid ? AppColors.ink : AppColors.mintText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.cobalt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.borderXs,
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(
          color: foreground,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}