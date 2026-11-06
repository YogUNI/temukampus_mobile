import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/data/models/user_model.dart';

/// Kartu data peserta (otomatis terisi dari akun, hanya-baca).
class RegistrationParticipantCard extends StatelessWidget {
  final UserModel? user;

  const RegistrationParticipantCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink100),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        children: [
          _DataRow(
            icon: Icons.person_outline_rounded,
            label: 'Nama Lengkap',
            value: user?.name ?? '-',
          ),
          const Divider(height: AppSpacing.xl),
          _DataRow(
            icon: Icons.badge_outlined,
            label: 'NIM Mahasiswa',
            value: user?.nim ?? 'Peserta Eksternal',
          ),
          const Divider(height: AppSpacing.xl),
          _DataRow(
            icon: Icons.school_outlined,
            label: 'Program Studi & Angkatan',
            value: user?.academicSummary ?? '-',
          ),
          const Divider(height: AppSpacing.xl),
          _DataRow(
            icon: Icons.phone_android_rounded,
            label: 'Nomor WhatsApp',
            value: user?.phone ?? '-',
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.cobalt),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  fontSize: 9.5,
                  color: AppColors.ink500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}