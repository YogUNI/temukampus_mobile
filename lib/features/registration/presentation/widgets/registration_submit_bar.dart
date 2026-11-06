import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';

/// Sticky bottom bar pengiriman pendaftaran: total di kiri, CTA lebar di kanan.
///
/// Tinggi tetap [contentHeight] untuk semua keadaan (gratis/berbayar/mengirim).
class RegistrationSubmitBar extends StatelessWidget {
  final bool isPaid;
  final bool isSubmitting;
  final bool canSubmit;
  final String totalText;
  final VoidCallback? onPressed;

  static const double contentHeight = 76;

  const RegistrationSubmitBar({
    super.key,
    required this.isPaid,
    required this.isSubmitting,
    required this.canSubmit,
    required this.totalText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.ink100)),
        boxShadow: AppShadows.liftedCard,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SizedBox(
          height: contentHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPaid ? 'TOTAL DITRANSFER' : 'BIAYA PENDAFTARAN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                          fontSize: 9.5,
                          color: AppColors.ink400,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        isPaid ? totalText : 'Gratis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isPaid ? AppColors.cobalt : AppColors.mintText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 6,
                  child: StickerButton(
                    label: isPaid ? 'Kirim & Bukti Bayar' : 'Konfirmasi Gratis',
                    variant: StickerButtonVariant.primary,
                    isLoading: isSubmitting,
                    onPressed: canSubmit ? onPressed : null,
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