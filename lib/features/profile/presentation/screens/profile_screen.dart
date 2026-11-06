import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          backgroundColor: AppColors.surface,
          title: Text('Konfirmasi Keluar', style: AppTypography.titleSmall),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun TemuKampus?',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: AppTypography.label.copyWith(color: AppColors.ink500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Profil Mahasiswa', style: AppTypography.titleMedium),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Avatar & Info Utama
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink200, width: 1.2),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.cobaltLight,
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: AppTypography.hero.copyWith(color: AppColors.cobalt, fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Mahasiswa UMB', style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user?.email ?? '', style: AppTypography.bodySmall),
                      if (user?.emailVerified ?? false) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.mint, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      user?.academicSummary ?? 'Mahasiswa UMB',
                      style: AppTypography.badge.copyWith(color: AppColors.cobalt),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detail Akun Card (Read-only NIM sesuai BR-23)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink200, width: 1.2),
              ),
              child: Column(
                children: [
                  _buildProfileRow('NIM Mahasiswa', user?.nim ?? '-', isReadOnly: true),
                  const Divider(height: 24),
                  _buildProfileRow('Program Studi', user?.studyProgram?.name ?? '-'),
                  const Divider(height: 24),
                  _buildProfileRow('Tahun Angkatan', user?.cohortYear?.toString() ?? '-'),
                  const Divider(height: 24),
                  _buildProfileRow('No. WhatsApp', user?.phone ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Tombol Logout Stiker
            StickerButton(
              label: 'Keluar dari Akun',
              variant: StickerButtonVariant.outline,
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
              onPressed: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isReadOnly = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Row(
          children: [
            Text(value, style: AppTypography.label.copyWith(fontSize: 13)),
            if (isReadOnly) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.ink400),
            ],
          ],
        ),
      ],
    );
  }
}

