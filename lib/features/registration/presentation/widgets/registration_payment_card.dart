import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../events/data/models/event_model.dart';
import '../../data/models/registration_model.dart';

/// Instruksi pembayaran manual: blok hero kode unik 3 digit + rincian biaya
/// + rekening tujuan panitia + peringatan transfer.
class RegistrationPaymentCard extends StatelessWidget {
  final PaymentPreviewModel? preview;
  final EventModel? event;
  final void Function(String text, String message) onCopy;

  const RegistrationPaymentCard({
    super.key,
    required this.preview,
    required this.event,
    required this.onCopy,
  });

  static const double uniqueCodeHeroSize = 38;

  @override
  Widget build(BuildContext context) {
    final uniqueCode = preview?.uniqueCode ?? 137;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instruksi Transfer Pembayaran', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.sm),

        // === HERO: KODE UNIK 3 DIGIT ===
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.signalLight,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.signal, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.signal,
                        borderRadius: AppRadii.borderXs,
                      ),
                      child: Text(
                        'KODE UNIK 3 DIGIT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StickerButton(
                    label: 'Salin',
                    fullWidth: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    variant: StickerButtonVariant.outline,
                    icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.ink),
                    onPressed: () {
                      AppHaptics.selection();
                      onCopy('$uniqueCode', 'Kode unik berhasil disalin!');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tambahkan kode ini di akhir nominal transfermu:',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.ink700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Rp ',
                    style: AppTypography.numericHero.copyWith(
                      fontSize: 18,
                      color: AppColors.signal,
                    ),
                  ),
                  Text(
                    '$uniqueCode',
                    style: AppTypography.numericHero.copyWith(
                      fontSize: uniqueCodeHeroSize,
                      color: AppColors.ink,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Contoh: tiket Rp 25.000 + kode 137 = transfer Rp 25.137.',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.ink500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // === RINCIAN BIAYA ===
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.ink100),
            boxShadow: AppShadows.softCard,
          ),
          child: Column(
            children: [
              _BreakdownRow(
                label: 'Harga Tiket',
                value: preview != null
                    ? AppFormatters.rupiah(preview!.ticketPrice)
                    : event?.formattedPrice ?? 'Rp 25.000',
              ),
              const SizedBox(height: AppSpacing.sm),
              _BreakdownRow(
                label: 'Kode Unik Transfer',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.signalLight,
                    borderRadius: AppRadii.borderXs,
                  ),
                  child: Text(
                    '3 DIGIT',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.ink,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                value: '+ Rp $uniqueCode',
                valueColor: AppColors.signal,
              ),
              const Divider(height: AppSpacing.xl),
              _BreakdownRow(
                label: 'TOTAL DITRANSFER',
                value: preview?.formattedTotal ?? 'Rp 25.137',
                valueStyle: AppTypography.titleMedium.copyWith(
                  color: AppColors.cobalt,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // === REKENING TUJUAN ===
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.ink100),
            boxShadow: AppShadows.softCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekening Tujuan Panitia',
                style: AppTypography.micro.copyWith(
                  color: AppColors.ink500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview?.bankName ?? event?.bankName ?? 'BCA (Bank Central Asia)',
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          preview?.accountNumber ?? event?.bankAccountNumber ?? '5410982311',
                          style: AppTypography.numericCode.copyWith(
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'a.n. ${preview?.accountName ?? event?.bankAccountName ?? "PANITIA ACARA"}',
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
                  IconButton(
                    tooltip: 'Salin nomor rekening',
                    icon: const Icon(Icons.copy_rounded, color: AppColors.cobalt),
                    onPressed: () {
                      AppHaptics.selection();
                      final acc = preview?.accountNumber ??
                          event?.bankAccountNumber ??
                          '5410982311';
                      onCopy(acc, 'Nomor rekening berhasil disalin!');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // === PERINGATAN ===
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: AppRadii.borderSm,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'PENTING: Transfer tepat sampai 3 digit terakhir agar pembayaran '
                  'dapat diverifikasi otomatis oleh sistem.',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final Color valueColor;
  final TextStyle? valueStyle;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor = AppColors.ink,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: valueStyle ??
                AppTypography.titleSmall.copyWith(
                  fontSize: 14,
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }
}