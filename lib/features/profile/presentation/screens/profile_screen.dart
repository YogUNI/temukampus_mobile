import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showLogoutDialog() {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) {
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Batal', style: AppTypography.label.copyWith(color: AppColors.ink500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(authNotifierProvider.notifier).logout();
                if (mounted) {
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

  void _showChangePasswordSheet() {
    AppHaptics.light();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Ubah Kata Sandi Akun', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Kata sandi baru minimal terdiri dari 8 karakter.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Saat Ini',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.cobalt),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.cobalt),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: StickerButton(
                      label: 'Simpan Kata Sandi',
                      variant: StickerButtonVariant.primary,
                      onPressed: () {
                        if (newPasswordController.text.trim().length >= 8) {
                          Navigator.pop(ctx);
                          AppHaptics.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi berhasil diperbarui!'),
                              backgroundColor: AppColors.mint,
                            ),
                          );
                        } else {
                          AppHaptics.error();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi baru minimal 8 karakter.'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditPhoneSheet(String? currentPhone) {
    AppHaptics.light();
    final phoneController = TextEditingController(text: currentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Perbarui Nomor WhatsApp', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Nomor aktif digunakan untuk konfirmasi e-tiket kegiatan.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp (08xxx)',
                      prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.cobalt),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: StickerButton(
                      label: 'Simpan Nomor',
                      variant: StickerButtonVariant.primary,
                      onPressed: () {
                        final val = phoneController.text.trim();
                        if (val.length >= 10) {
                          Navigator.pop(ctx);
                          AppHaptics.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor WhatsApp berhasil diperbarui!'),
                              backgroundColor: AppColors.mint,
                            ),
                          );
                        } else {
                          AppHaptics.error();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor WhatsApp tidak valid.'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangeAvatarSheet() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.ink200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Ubah Foto Profil', style: AppTypography.titleMedium),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.cobalt),
                  title: Text('Ambil dari Kamera', style: AppTypography.titleSmall),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final data = await AppImageHelper.pickImage(ImageSource.camera);
                    if (data != null && mounted) {
                      AppHaptics.success();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foto profil berhasil diubah.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.mintText),
                  title: Text('Pilih dari Galeri', style: AppTypography.titleSmall),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final data = await AppImageHelper.pickImage(ImageSource.gallery);
                    if (data != null && mounted) {
                      AppHaptics.success();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foto profil berhasil diubah.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(String title, String content) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        title: Text(title, style: AppTypography.titleMedium),
        content: Text(content, style: AppTypography.bodySmall),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cobalt, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // 1. Avatar & Info Utama
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink, width: 1.4),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.cobaltLight,
                        child: Text(
                          user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: AppTypography.hero.copyWith(color: AppColors.cobalt, fontSize: 30),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showChangeAvatarSheet,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.cobalt,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Mahasiswa UMB', style: AppTypography.titleMedium.copyWith(fontSize: 17)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user?.email ?? '', style: AppTypography.bodySmall),
                      if (user?.emailVerified ?? false) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.mint, size: 15),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
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
            const SizedBox(height: 18),

            // 2. Akumulasi Poin SKP Kemahasiswaan
            TicketContainer(
              punchRadius: 10.0,
              punchPositionPercent: 0.5,
              borderRadius: 14.0,
              borderColor: AppColors.ink,
              borderWidth: 1.2,
              hasShadow: true,
              shadowOffset: const Offset(2.5, 2.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mintLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.stars_rounded, color: AppColors.mint, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AKUMULASI SKP', style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.ink400)),
                            Text('12 Poin Terkumpul', style: AppTypography.titleSmall.copyWith(fontSize: 15, color: AppColors.mintText)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('AKTIF', style: AppTypography.badge.copyWith(color: AppColors.mintText, fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Banner Pintu Masuk Panitia Hari-H (Hanya Muncul untuk Admin / Panitia)
            if (user?.canScanTickets ?? false) ...[
              GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  context.push(AppRoutes.scannerSelectEvent);
                },
                child: TicketContainer(
                  punchRadius: 12.0,
                  punchPositionPercent: 0.65,
                  borderRadius: 14.0,
                  borderColor: AppColors.ink,
                  borderWidth: 1.5,
                  color: AppColors.signalLight,
                  hasShadow: true,
                  shadowOffset: const Offset(3, 3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.signal,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.ink, width: 1.2),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.ink, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'MODE PANITIA AKTIF',
                                    style: AppTypography.badge.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 10),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.signal, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Buka Scanner Presensi Hari-H',
                                style: AppTypography.titleSmall.copyWith(fontSize: 14),
                              ),
                              Text(
                                'Pindai QR code tiket peserta di pintu gerbang',
                                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 4. Detail Identitas Akademik Mahasiswa UMB (Read-Only Sesuai BR-23)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink200, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Data Identitas Akademik', style: AppTypography.titleSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ink100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, size: 10, color: AppColors.ink500),
                            const SizedBox(width: 3),
                            Text('RESMI UMB', style: AppTypography.badge.copyWith(fontSize: 8, color: AppColors.ink700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildProfileRow('NIM Mahasiswa', user?.nim ?? '-', isReadOnly: true),
                  const Divider(height: 20),
                  _buildProfileRow('Program Studi', user?.studyProgram?.name ?? '-', isReadOnly: true),
                  const Divider(height: 20),
                  _buildProfileRow('Tahun Angkatan', user?.cohortYear?.toString() ?? '-', isReadOnly: true),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No. WhatsApp', style: AppTypography.bodyMedium),
                          Text(user?.phone ?? '-', style: AppTypography.label.copyWith(fontSize: 13)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showEditPhoneSheet(user?.phone),
                        child: Text('Ubah', style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 5. Menu Pengaturan & Informasi
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink200, width: 1.2),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppColors.cobalt),
                    title: Text('Ubah Kata Sandi', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: _showChangePasswordSheet,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.cobalt),
                    title: Text('Syarat & Ketentuan', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: () => _showInfoDialog(
                      'Syarat & Ketentuan',
                      'TemuKampus adalah platform resmi civitas akademika Universitas Mercu Buana. Pengguna wajib menggunakan data akademik yang valid dan menjaga kerahasiaan tiket digital masing-masing.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.cobalt),
                    title: Text('Kebijakan Privasi', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: () => _showInfoDialog(
                      'Kebijakan Privasi',
                      'Data NIM, Program Studi, dan Nomor WhatsApp hanya digunakan untuk keperluan verifikasi pendaftaran, penerbitan tiket, serta komunikasi kepanitiaan kegiatan kampus.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.cobalt),
                    title: Text('Bantuan Kemahasiswaan', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: () => _showInfoDialog(
                      'Bantuan Kemahasiswaan',
                      'Jika terdapat kendala pada tiket atau akun, silakan hubungi Biro Kemahasiswaan UMB Tower Lt. 2 atau kirim pesan WhatsApp ke Layanan Mahasiswa UMB.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 6. Tombol Logout Stiker
            SizedBox(
              width: double.infinity,
              child: StickerButton(
                label: 'Keluar dari Akun',
                variant: StickerButtonVariant.outline,
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                onPressed: _showLogoutDialog,
              ),
            ),
            const SizedBox(height: 36),
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
