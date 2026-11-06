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
import 'event_grid_metrics.dart';

/// Kartu acara grid 2-kolom (inspirasi: grid e-commerce modern).
///
/// Tahan teks panjang: area judul memakai [Expanded] sehingga sisa ruang
/// vertikal diserap judul, bukan meluber keluar kartu. Tinggi kartu ditentukan
/// oleh [EventGridMetrics], bukan `childAspectRatio`.
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: EventGridMetrics.posterAspectRatio,
                  child: _PosterLayer(event: event, isLowQuota: isLowQuota),
                ),
                Expanded(
                  child: Padding(
                    padding: AppSpacing.cardCompact,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Penyelenggara (eyebrow)
                        Text(
                          event.organization.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.micro.copyWith(
                            color: AppColors.cobalt,
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Judul — menyerap sisa tinggi, tidak pernah meluber.
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Tanggal
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppColors.ink400,
                            ),
                            const SizedBox(width: AppSpacing.xs),
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
                        const SizedBox(height: AppSpacing.sm),

                        // Harga + aksi masuk
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.formattedPrice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: event.isPaid ? AppColors.ink : AppColors.mintText,
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.cobalt,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                size: 17,
                                color: Colors.white,
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
          ),
        ),
      ),
    );
  }
}

class _PosterLayer extends StatelessWidget {
  final EventModel event;
  final bool isLowQuota;

  const _PosterLayer({required this.event, required this.isLowQuota});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkOrAssetImage(
          imagePath: event.posterUrl,
          fit: BoxFit.cover,
        ),
        // Scrim tipis hanya di bagian atas — cukup membuat badge putih terbaca
        // pada poster terang tanpa menggelapkan fotonya.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.22),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55],
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Row(
            children: [
              Flexible(
                child: _ImageTag(
                  label: event.format.toUpperCase(),
                  background: Colors.white.withValues(alpha: 0.94),
                  foreground: AppColors.ink,
                ),
              ),
              if (event.skpPoints > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                _ImageTag(
                  label: '${event.skpPoints} SKP',
                  background: AppColors.cobalt,
                  foreground: Colors.white,
                ),
              ],
              const Spacer(),
              if (isLowQuota)
                _ImageTag(
                  label: 'Sisa ${event.remainingQuota}',
                  background: AppColors.signal,
                  foreground: AppColors.ink,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _ImageTag({
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.micro.copyWith(
          color: foreground,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
