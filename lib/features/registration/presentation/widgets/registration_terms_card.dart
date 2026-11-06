import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Persetujuan syarat & privasi + tampilan error server saat pengiriman.
class RegistrationTermsCard extends StatelessWidget {
  final bool termsAccepted;
  final String? errorMessage;
  final ValueChanged<bool> onTermsChanged;

  const RegistrationTermsCard({
    super.key,
    required this.termsAccepted,
    required this.errorMessage,
    required this.onTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onTermsChanged(!termsAccepted),
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: termsAccepted,
                activeColor: AppColors.cobalt,
                onChanged: (val) => onTermsChanged(val ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Saya menyetujui data diri saya digunakan oleh panitia pelaksana '
                    'untuk keperluan registrasi dan penerbitan tiket kegiatan ini.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: AppRadii.borderSm,
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.dangerText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}