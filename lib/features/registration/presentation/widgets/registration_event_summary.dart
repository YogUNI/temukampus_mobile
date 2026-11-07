import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../events/data/models/event_model.dart';

/// Ringkasan singkat acara di puncak formulir pendaftaran.
class RegistrationEventSummary extends StatelessWidget {
  final EventModel? event;

  const RegistrationEventSummary({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink200),
        boxShadow: AppShadows.softCard,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadii.borderSm,
            child: AppNetworkOrAssetImage(
              imagePath: event!.posterUrl,
              // 4:5 — rasio master poster backend (1080×1350).
              width: 42,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${AppFormatters.eventDate(event!.startAt)} • ${event!.formatLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}