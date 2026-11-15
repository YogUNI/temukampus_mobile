import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../auth/data/models/user_model.dart';

/// Header personal Beranda: avatar, sapaan + identitas akademik, lonceng notifikasi.
class HomeHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onNotificationTap;

  /// Jumlah notifikasi belum dibaca; 0 menyembunyikan badge.
  final int unreadCount;

  const HomeHeader({
    super.key,
    required this.user,
    required this.onNotificationTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cobalt, width: 1.5),
            boxShadow: AppShadows.softCard,
          ),
          child: ClipOval(
            child: user != null
                ? const AppNetworkOrAssetImage(
                    imagePath: 'assets/images/avatars/user_avatar.jpg',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.cobaltLight,
                    child: const Icon(
                      Icons.person_rounded,
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
                user != null ? 'Halo, ${user!.name.split(' ').first}!' : 'Halo, Kawan Kampus!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                user?.isUmbStudent == true
                    ? '${user?.studyProgram?.name ?? "Teknik Informatika"} · Angkatan ${user?.cohortYear ?? 24}'
                    : 'Mode Tamu · Eksplorasi acara kampus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  color: AppColors.ink500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () {
            AppHaptics.light();
            onNotificationTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink100),
              boxShadow: AppShadows.softCard,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.signal,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          height: 1.1,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
