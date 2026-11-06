import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// Indikator visual progres sisa kuota tiket acara (BR-05).
/// Warna otomatis berubah: Mint (<70%) -> Kuning/Amber (70-89%) -> Signal Oranye (>=90%) -> Bahaya/Merah (Penuh 100%).
class QuotaProgressBar extends StatelessWidget {
  final int? quota;
  final int? remainingQuota;
  final int registeredCount;
  final bool isFull;

  const QuotaProgressBar({
    super.key,
    required this.quota,
    required this.remainingQuota,
    this.registeredCount = 0,
    this.isFull = false,
  });

  @override
  Widget build(BuildContext context) {
    if (quota == null || quota! <= 0) {
      // Kuota tidak dibatasi
      return Row(
        children: [
          const Icon(Icons.all_inclusive_rounded, size: 16, color: AppColors.cobalt),
          const SizedBox(width: 6),
          Text(
            'Kuota Terbuka (Tanpa Batas)',
            style: AppTypography.badge.copyWith(color: AppColors.ink700, fontSize: 11),
          ),
        ],
      );
    }

    final total = quota!;
    final remaining = remainingQuota ?? (total - registeredCount).clamp(0, total);
    final filled = (total - remaining).clamp(0, total);
    final fillRatio = (filled / total).clamp(0.0, 1.0);
    final percentage = (fillRatio * 100).round();

    final Color barColor;
    final Color badgeBg;
    final Color badgeText;
    final String statusLabel;

    if (isFull || remaining <= 0) {
      barColor = AppColors.danger;
      badgeBg = AppColors.dangerLight;
      badgeText = AppColors.dangerText;
      statusLabel = 'Kuota Penuh';
    } else if (fillRatio >= 0.90 || remaining <= 5) {
      barColor = AppColors.signal;
      badgeBg = AppColors.signalLight;
      badgeText = AppColors.ink;
      statusLabel = 'Sisa $remaining tiket!';
    } else if (fillRatio >= 0.70) {
      barColor = AppColors.warning;
      badgeBg = AppColors.warningLight;
      badgeText = AppColors.warningText;
      statusLabel = 'Tersisa $remaining tiket ($percentage%)';
    } else {
      barColor = AppColors.mint;
      badgeBg = AppColors.mintLight;
      badgeText = AppColors.mintText;
      statusLabel = 'Tersedia $remaining dari $total tiket';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.ink500),
                const SizedBox(width: 6),
                Text(
                  'Kapasitas Peserta',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.ink500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isFull || remaining <= 0 ? AppColors.danger : AppColors.ink.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                statusLabel,
                style: AppTypography.badge.copyWith(
                  color: badgeText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress Bar dengan Motif Stiker Kampus
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.ink100,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 1.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fillRatio,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Label Info Numerik
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$filled terdaftar',
              style: AppTypography.numericCode.copyWith(fontSize: 10, color: AppColors.ink500),
            ),
            Text(
              'Maks. $total peserta',
              style: AppTypography.numericCode.copyWith(fontSize: 10, color: AppColors.ink500),
            ),
          ],
        ),
      ],
    );
  }
}
