import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Lembar catatan untuk permintaan revisi / penolakan pendaftaran / pembatalan acara.
///
/// Mengembalikan teks catatan, atau `null` bila dibatalkan. Alasan wajib
/// diisi minimal [minLength] karakter (default 5, pembatalan acara 10)
/// karena peserta akan menerimanya sebagai pemberitahuan resmi.
Future<String?> showReviewNoteSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  String? subtitle,
  int minLength = 5,
  bool destructive = false,
}) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final currentLength = controller.text.trim().length;
        final isValid = currentLength >= minLength;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.ink200,
                      borderRadius: AppRadii.borderPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ?? 'Catatan ini dikirim ke peserta lewat email dan notifikasi.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (_) => setModalState(() {}),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: AppColors.paper,
                    helperText: 'Minimal $minLength karakter (saat ini $currentLength)',
                    helperStyle: AppTypography.micro.copyWith(
                      color: isValid ? AppColors.mintText : AppColors.ink500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.borderMd,
                      borderSide: BorderSide(color: AppColors.ink200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.borderMd,
                      borderSide: BorderSide(
                        color: currentLength > 0 && !isValid
                            ? AppColors.signal
                            : AppColors.ink200,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.borderMd,
                      borderSide: BorderSide(
                        color: destructive ? AppColors.danger : AppColors.cobalt,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: isValid
                            ? () => Navigator.of(ctx).pop(controller.text.trim())
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              destructive ? AppColors.danger : AppColors.cobalt,
                          disabledBackgroundColor: AppColors.ink200,
                        ),
                        child: Text(
                          confirmLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isValid ? AppColors.surface : AppColors.ink400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
