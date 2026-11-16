import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';

/// Lembar konfirmasi keluar akun.
///
/// Menggantikan `AlertDialog` bawaan: kartu bergaya tiket dengan perforasi,
/// avatar pengguna, dan dua aksi yang jelas bedanya (tetap di sini vs keluar).
Future<bool> showLogoutSheet(
  BuildContext context, {
  String? name,
  String? subtitle,
  String? avatarUrl,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (ctx) => _LogoutSheet(
      name: name,
      subtitle: subtitle,
      avatarUrl: avatarUrl,
    ),
  );

  return result ?? false;
}

class _LogoutSheet extends StatelessWidget {
  final String? name;
  final String? subtitle;
  final String? avatarUrl;

  const _LogoutSheet({this.name, this.subtitle, this.avatarUrl});

  String get _initials {
    final source = (name ?? '').trim();

    if (source.isEmpty) return 'TK';

    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderXl,
          boxShadow: AppShadows.liftedCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pegangan tarik
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // Foto profil asli bila ada; inisial sebagai cadangan.
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cobaltLight,
                      border: Border.all(color: AppColors.cobalt, width: 2),
                    ),
                    child: ClipOval(
                      child: AppNetworkOrAssetImage(
                        imagePath: avatarUrl,
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                        errorWidget: Center(
                          child: Text(
                            _initials,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.cobalt,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Keluar dari akun?',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (name != null && name!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      name!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(color: AppColors.cobalt),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle ??
                        'Kamu bisa masuk lagi kapan saja. Tiket dan riwayat pendaftaranmu tetap tersimpan aman.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Garis perforasi: pemisah bergaya sobekan tiket.
            _PerforatedDivider(),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  StickerButton(
                    label: 'Ya, Keluar Sekarang',
                    variant: StickerButtonVariant.danger,
                    borderRadius: AppRadii.sm,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StickerButton(
                    label: 'Tetap di Sini',
                    variant: StickerButtonVariant.outline,
                    borderRadius: AppRadii.sm,
                    onPressed: () => Navigator.of(context).pop(false),
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

/// Garis putus-putus dengan cekungan di kedua ujung (motif sobekan tiket).
class _PerforatedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          // Cekungan kiri
          Container(
            width: 12,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashWidth = 6.0;
                final count = (constraints.maxWidth / (dashWidth * 2)).floor();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: dashWidth,
                      height: 1.6,
                      color: AppColors.ink200,
                    ),
                  ),
                );
              },
            ),
          ),
          // Cekungan kanan
          Container(
            width: 12,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
