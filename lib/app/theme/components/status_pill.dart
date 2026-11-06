import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

enum RegistrationStatusType {
  pendingVerification,
  needsRevision,
  confirmed,
  rejected,
  cancelled;

  static RegistrationStatusType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'needs_revision':
        return RegistrationStatusType.needsRevision;
      case 'confirmed':
        return RegistrationStatusType.confirmed;
      case 'rejected':
        return RegistrationStatusType.rejected;
      case 'cancelled':
        return RegistrationStatusType.cancelled;
      case 'pending_verification':
      default:
        return RegistrationStatusType.pendingVerification;
    }
  }

  String get label {
    switch (this) {
      case RegistrationStatusType.pendingVerification:
        return 'Menunggu Verifikasi';
      case RegistrationStatusType.needsRevision:
        return 'Perlu Revisi';
      case RegistrationStatusType.confirmed:
        return 'Terkonfirmasi';
      case RegistrationStatusType.rejected:
        return 'Ditolak';
      case RegistrationStatusType.cancelled:
        return 'Dibatalkan';
    }
  }

  IconData get icon {
    switch (this) {
      case RegistrationStatusType.pendingVerification:
        return Icons.hourglass_top_rounded;
      case RegistrationStatusType.needsRevision:
        return Icons.edit_note_rounded;
      case RegistrationStatusType.confirmed:
        return Icons.check_circle_rounded;
      case RegistrationStatusType.rejected:
        return Icons.cancel_rounded;
      case RegistrationStatusType.cancelled:
        return Icons.block_rounded;
    }
  }
}

/// Badge Status Pendaftaran & Tiket TemuKampus.
/// Mendukung mode biasa ([isStamp] = false) dan mode cap stempel fisik ([isStamp] = true, miring -3°).
class StatusPill extends StatelessWidget {
  final RegistrationStatusType status;
  final bool isStamp;
  final double? angle; // Custom angle dalam radian, default -3 derajat jika isStamp true

  const StatusPill({
    super.key,
    required this.status,
    this.isStamp = false,
    this.angle,
  });

  factory StatusPill.fromBackend(String? statusString, {bool isStamp = false}) {
    return StatusPill(
      status: RegistrationStatusType.fromString(statusString),
      isStamp: isStamp,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;

    switch (status) {
      case RegistrationStatusType.pendingVerification:
        bg = AppColors.amberLight;
        text = AppColors.amber;
        border = AppColors.amber.withValues(alpha: 0.4);
        break;
      case RegistrationStatusType.needsRevision:
        // Rule: Teks di atas warna signal wajib AppColors.ink
        bg = AppColors.signalLight;
        text = AppColors.ink;
        border = AppColors.signal;
        break;
      case RegistrationStatusType.confirmed:
        bg = AppColors.mintLight;
        text = AppColors.mintText;
        border = AppColors.mint.withValues(alpha: 0.4);
        break;
      case RegistrationStatusType.rejected:
        bg = AppColors.dangerLight;
        text = AppColors.dangerText;
        border = AppColors.danger.withValues(alpha: 0.4);
        break;
      case RegistrationStatusType.cancelled:
        bg = AppColors.ink100;
        text = AppColors.ink500;
        border = AppColors.ink300;
        break;
    }

    if (isStamp) {
      // Tampilan Cap Stempel Fisik (Miring -3°)
      final stampAngle = angle ?? (-3.0 * math.pi / 180.0);

      return Transform.rotate(
        angle: stampAngle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: text, width: 2),
            boxShadow: [
              BoxShadow(
                color: text.withValues(alpha: 0.25),
                offset: const Offset(1, 1),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 14, color: text),
              const SizedBox(width: 5),
              Text(
                status.label.toUpperCase(),
                style: AppTypography.ticketStamp.copyWith(
                  color: text,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan Pill Badge Halus
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.badge.copyWith(color: text),
          ),
        ],
      ),
    );
  }
}
