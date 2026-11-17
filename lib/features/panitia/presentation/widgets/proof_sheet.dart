import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/panitia_models.dart';

/// Menampilkan bukti transfer peserta dalam lembar bawah (zoomable).
///
/// Panitia perlu membandingkan nominal di struk dengan tagihan sebelum
/// menyetujui, jadi gambar ditampilkan besar dan bisa dicubit.
Future<void> showProofSheet(BuildContext context, RegistrantModel registrant) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ink200,
                borderRadius: AppRadii.borderPill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti transfer',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${registrant.name} · ${registrant.formattedTotal}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),
            Expanded(
              child: registrant.proofUrl == null
                  ? Center(
                      child: Text(
                        'Bukti transfer belum diunggah.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                      ),
                    )
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        registrant.proofUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.cobalt),
                          );
                        },
                        errorBuilder: (context, error, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              'Gambar tidak bisa dimuat. Periksa koneksi lalu coba lagi.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.ink500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
