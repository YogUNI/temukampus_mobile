import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Hitung label hitung mundur hari-H untuk tiket.
///
/// Murni (tanpa dependensi waktu global) supaya bisa diuji.
class TicketCountdown {
  TicketCountdown._();

  static String label(DateTime startAt, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final eventDay = _dateOnly(startAt);
    final diff = eventDay.difference(today).inDays;

    if (diff > 1) return 'H-$diff';
    if (diff == 1) return 'Besok';
    if (diff == 0) return 'Hari ini';
    return 'Selesai';
  }

  /// Hari ini atau besok → ditandai mendesak (warna Signal).
  static bool isUrgent(DateTime startAt, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final diff = _dateOnly(startAt).difference(today).inDays;
    return diff >= 0 && diff <= 1;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// Chip hitung mundur hari-H.
class TicketCountdownChip extends StatelessWidget {
  final DateTime startAt;

  const TicketCountdownChip({super.key, required this.startAt});

  @override
  Widget build(BuildContext context) {
    final label = TicketCountdown.label(startAt);
    final urgent = TicketCountdown.isUrgent(startAt);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: urgent ? AppColors.signal : AppColors.ink100,
        borderRadius: AppRadii.borderXs,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: AppTypography.micro.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: urgent ? AppColors.ink : AppColors.ink700,
        ),
      ),
    );
  }
}
