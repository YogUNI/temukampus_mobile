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
import '../../../../shared/widgets/app_network_or_asset_image.dart';
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

  void _showFaqSheet() {
    AppHaptics.light();
    final faqs = [
      {
        'q': 'Bagaimana cara pendaftaran acara berbayar?',
        'a': 'Pilih acara, lalu transfer ke rekening panitia sesuai nominal tepat hingga 3 digit kode unik. Unggah foto bukti transfer struk / m-banking. Panitia akan memverifikasi maksimal 1x24 jam.'
      },
      {
        'q': 'Bagaimana cara presensi saat hari-H acara?',
        'a': 'Buka tab "Tiket Saya", pilih tiket dengan status Terkonfirmasi, lalu tunjukkan kode QR kepada panitia di meja registrasi gerbang kampus untuk dipindai.'
      },
      {
        'q': 'Apa itu Poin SKP kemahasiswaan?',
        'a': 'SKP (Satuan Kredit Partisipasi) adalah poin kegiatan resmi mahasiswa Universitas Mercu Buana yang terakumulasi sebagai syarat kelulusan dan SKPI.'
      },
      {
        'q': 'Kapan link grup WhatsApp peserta dibuka?',
        'a': 'Tautan grup WhatsApp dan tautan meeting daring akan otomatis terbuka setelah pendaftaran Anda disetujui (Confirmed) oleh panitia sesuai aturan privasi kampus.'
      },
      {
        'q': 'Apa yang harus dilakukan jika bukti transfer perlu revisi?',
        'a': 'Buka rincian tiket berstatus "Perlu Revisi", baca catatan panitia, lalu tekan tombol "Unggah Ulang Bukti Bayar" dengan foto struk yang lebih jelas dan terbaca.'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cobaltLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help_center_rounded, color: AppColors.cobalt, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pusat Bantuan & Tanya Jawab', style: AppTypography.titleMedium),
                        Text('Pertanyaan umum seputar kegiatan kampus UMB', style: AppTypography.bodySmall.copyWith(color: AppColors.ink500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: faqs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = faqs[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.ink100, width: 1.2),
                        ),
                        child: Theme(
                          data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            title: Text(
                              item['q']!,
                              style: AppTypography.titleSmall.copyWith(fontSize: 13),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                                child: Text(
                                  item['a']!,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink700, height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutAppSheet() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cobalt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 14),
                Text('TemuKampus Mobile', style: AppTypography.hero.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text('Versi 1.0.0 (Build 2025.1) • Official Campus App', style: AppTypography.bodySmall.copyWith(color: AppColors.ink500)),
                const SizedBox(height: 14),
                Text(
                  'Aplikasi resmi mahasiswa Universitas Mercu Buana untuk eksplorasi kegiatan kampus, pendaftaran otomatis berbasis NIM, tiket digital presensi ber-QR, dan verifikasi kegiatan ber-SKP.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink700, height: 1.45),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ink100),
                  ),
                  child: Text(
                    'Universitas Mercu Buana — Kampus Meruya, Jakarta Barat',
                    style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    label: 'Tutup',
                    variant: StickerButtonVariant.outline,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Tampilan Mode Tamu (Guest Mode)
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          title: Text('Profil Pengguna', style: AppTypography.titleMedium),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Kartu Tamu Motif Tiket
              TicketContainer(
                punchRadius: 12.0,
                punchPositionPercent: 0.5,
                borderRadius: 16.0,
                borderColor: AppColors.ink,
                borderWidth: 1.5,
                hasShadow: true,
                shadowOffset: const Offset(3, 3),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.cobaltLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cobalt, width: 1.5),
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: AppColors.cobalt, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text('Mode Tamu (Eksplorasi)', style: AppTypography.hero.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        'Masuk dengan akun mahasiswa UMB untuk melihat profil lengkap, akumulasi poin SKP, dan mengelola tiket acara Anda.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.ink500, height: 1.4),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: StickerButton(
                          label: 'Masuk ke Akun',
                          variant: StickerButtonVariant.primary,
                          icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                          onPressed: () {
                            AppHaptics.selection();
                            context.push(AppRoutes.login);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: StickerButton(
                          label: 'Daftar Akun Baru',
                          variant: StickerButtonVariant.outline,
                          onPressed: () {
                            AppHaptics.selection();
                            context.push(AppRoutes.register);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Menu Informasi Tambahan untuk Tamu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink200, width: 1.2),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: AppColors.cobalt),
                      title: Text('Pusat Bantuan & Tanya Jawab', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                      onTap: _showFaqSheet,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.cobalt),
                      title: Text('Tentang TemuKampus', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                      onTap: _showAboutAppSheet,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.cobalt),
                      title: Text('Syarat & Ketentuan', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                      onTap: () => _showAboutAppSheet(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      );
    }

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
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cobalt, width: 2),
                        ),
                        child: ClipOval(
                          child: const AppNetworkOrAssetImage(
                            imagePath: 'assets/images/avatars/user_avatar.jpg',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
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
                  Text(user.name, style: AppTypography.titleMedium.copyWith(fontSize: 17)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.email, style: AppTypography.bodySmall),
                      if (user.emailVerified) ...[
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
                      user.academicSummary,
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
            if (user.canScanTickets) ...[
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
                  _buildProfileRow('NIM Mahasiswa', user.nim ?? '-', isReadOnly: true),
                  const Divider(height: 20),
                  _buildProfileRow('Program Studi', user.studyProgram?.name ?? '-', isReadOnly: true),
                  const Divider(height: 20),
                  _buildProfileRow('Tahun Angkatan', user.cohortYear?.toString() ?? '-', isReadOnly: true),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No. WhatsApp', style: AppTypography.bodyMedium),
                          Text(user.phone ?? '-', style: AppTypography.label.copyWith(fontSize: 13)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showEditPhoneSheet(user.phone),
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
                    leading: const Icon(Icons.help_center_rounded, color: AppColors.cobalt),
                    title: Text('Pusat Bantuan & Tanya Jawab', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: _showFaqSheet,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.cobalt),
                    title: Text('Tentang TemuKampus', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: _showAboutAppSheet,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.cobalt),
                    title: Text('Syarat & Ketentuan', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: _showAboutAppSheet,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.cobalt),
                    title: Text('Kebijakan Privasi', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink400),
                    onTap: _showAboutAppSheet,
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
