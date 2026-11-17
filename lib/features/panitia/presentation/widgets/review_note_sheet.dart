import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Lembar catatan untuk permintaan revisi / penolakan pendaftaran.
///
/// Mengembalikan teks catatan, atau `null` bila dibatalkan. Alasan wajib
/// diisi minimal 5 karakter karena peserta akan menerimanya sebagai
/// pemberitahuan resmi.
Future<String?> showReviewNoteSheet(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  bool destructive = false,
}) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (ctx) => Padding(
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
              'Catatan ini dikirim ke peserta lewat email dan notifikasi.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.borderMd,
                  borderSide: BorderSide(color: AppColors.ink200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadii.borderMd,
                  borderSide: BorderSide(color: AppColors.ink200),
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
                    onPressed: () {
                      final text = controller.text.trim();

                      if (text.length < 5) return;

                      Navigator.of(ctx).pop(text);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: destructive ? AppColors.danger : AppColors.cobalt,
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
