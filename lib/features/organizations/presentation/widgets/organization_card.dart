import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/organization_model.dart';

/// Kartu satu organisasi di direktori.
///
/// Menampilkan logo (atau inisial bila belum ada), nama, jenis, fakultas, dan
/// jumlah acara mendatang — informasi yang sama dengan kartu di web.
class OrganizationCard extends StatelessWidget {
  final OrganizationModel organization;
  final VoidCallback onTap;

  const OrganizationCard({
    super.key,
    required this.organization,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (organization.typeLabel != null) organization.typeLabel!,
      if (organization.facultyName != null) organization.facultyName!,
    ].join(' · ');

    return Semantics(
      button: true,
      label: 'Buka profil ${organization.name}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.ink200, width: 1.4),
            boxShadow: AppShadows.softCard,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.cobaltLight,
                  borderRadius: AppRadii.borderMd,
                  border: Border.all(color: AppColors.ink200, width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkOrAssetImage(
                  imagePath: organization.logoUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: Center(
                    child: Text(
                      organization.initials,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.cobalt,
                        fontWeight: FontWeight.w800,
                      ),
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
                      organization.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 14,
                          color: organization.upcomingEventsCount > 0
                              ? AppColors.cobalt
                              : AppColors.ink400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          organization.upcomingEventsCount > 0
                              ? '${organization.upcomingEventsCount} acara mendatang'
                              : 'Belum ada acara mendatang',
                          style: AppTypography.micro.copyWith(
                            color: organization.upcomingEventsCount > 0
                                ? AppColors.cobalt
                                : AppColors.ink400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink400),
            ],
          ),
        ),
      ),
    );
  }
}
