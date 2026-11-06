import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/nim_parser.dart';

/// Pratinjau NIM langsung (client-side preview BR-01..BR-03).
///
/// Tiga keadaan: belum diisi, valid (prodi + angkatan + fakultas), dan tidak
/// valid (pesan galat dari [NimParser]).
class RegisterNimPreview extends StatelessWidget {
  final String rawNim;
  final NimResult result;

  const RegisterNimPreview({
    super.key,
    required this.rawNim,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (rawNim.isEmpty) {
      return _Shell(
        background: AppColors.paper,
        borderColor: AppColors.ink200,
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.ink400,
              size: 15,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ketik 11 digit NIM untuk memverifikasi program studi dan angkatan.',
                style: AppTypography.micro.copyWith(
                  fontSize: 10.5,
                  color: AppColors.ink400,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!result.isValid) {
      return _Shell(
        background: AppColors.signalLight,
        borderColor: AppColors.signal.withValues(alpha: 0.45),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.pending_outlined,
              color: AppColors.ink,
              size: 15,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                result.errorMessage ?? 'NIM belum valid.',
                style: AppTypography.micro.copyWith(
                  fontSize: 10.5,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _Shell(
      background: AppColors.cobaltLight,
      borderColor: AppColors.cobalt.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.cobalt,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.programName ?? 'Program Studi Valid',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.cobalt,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(label: 'Kode: ${result.programCode}'),
              _Chip(label: 'Angkatan: ${result.cohortYear}'),
              if (result.facultyName != null)
                _Chip(label: result.facultyName!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  final Widget child;
  final Color background;
  final Color borderColor;

  const _Shell({
    required this.child,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.borderXs,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          fontSize: 9.5,
          color: AppColors.cobalt,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
