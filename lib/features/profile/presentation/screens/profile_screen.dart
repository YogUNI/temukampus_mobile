import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/haptics.dart';
import '../../../notifications/presentation/providers/notification_permission_provider.dart';
import 'dart:typed_data';


import '../../../../core/utils/image_compressor.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../screens/avatar_crop_screen.dart';
import '../widgets/logout_sheet.dart';
import '../widgets/profile_hero_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _showLogoutDialog() async {
    AppHaptics.light();

    final user = ref.read(authNotifierProvider).user;

    final confirmed = await showLogoutSheet(
      context,
      name: user?.name,
      avatarUrl: user?.avatarUrl,
      subtitle: user?.nim != null
          ? 'NIM ${user!.nim} akan keluar dari perangkat ini. Tiket dan riwayatmu tetap tersimpan.'
          : null,
    );

    if (!confirmed || !mounted) return;

    await ref.read(authNotifierProvider.notifier).logout();

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  /// Snackbar ringkas dengan warna status (mint = sukses, danger = galat).
  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.mint,
      ),
    );
  }

  /// Ambil foto → atur (crop/zoom) → unggah ke `POST /profile/avatar`.
  Future<void> _handleAvatarPick(ImageSource source) async {
    final data = await AppImageHelper.pickImage(source);

    if (!mounted) return;

    // Jangan diam saja: dulu tombol ini terasa mati karena batal/gagal
    // tidak memberi pesan apa pun.
    if (data == null) {
      _showSnack(
        context,
        'Tidak ada foto yang dipilih. Coba lagi ya.',
        isError: true,
      );
      return;
    }

    // Tegakkan orientasi dulu supaya bingkai crop & hasilnya tidak gepeng.
    final upright = await AppImageHelper.normalizeOrientation(data.bytes);

    if (!mounted) return;

    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => AvatarCropScreen(bytes: upright),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || cropped == null) return;

    final croppedData = PickedImageData(
      file: XFile.fromData(
        cropped,
        name: 'avatar.png',
        mimeType: 'image/png',
      ),
      bytes: cropped,
      sizeInBytes: cropped.lengthInBytes,
      fileName: 'avatar.png',
    );

    final error = await ref
        .read(authNotifierProvider.notifier)
        .updateAvatar(croppedData);
    if (!mounted) return;

    if (error == null) {
      AppHaptics.success();
      _showSnack(context, 'Foto profil berhasil diubah.');
    } else {
      AppHaptics.error();
      _showSnack(context, error, isError: true);
    }
  }

  void _showChangePasswordSheet() {
    AppHaptics.light();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

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
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Ulangi Kata Sandi Baru',
                      prefixIcon: Icon(Icons.verified_user_rounded, color: AppColors.cobalt),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: StickerButton(
                      label: 'Simpan Kata Sandi',
                      variant: StickerButtonVariant.primary,
                      onPressed: () async {
                        final current = oldPasswordController.text;
                        final next = newPasswordController.text;
                        final confirm = confirmController.text;

                        if (next.trim().length < 8) {
                          AppHaptics.error();
                          _showSnack(ctx, 'Kata sandi baru minimal 8 karakter.', isError: true);
                          return;
                        }

                        if (next != confirm) {
                          AppHaptics.error();
                          _showSnack(ctx, 'Konfirmasi kata sandi tidak cocok.', isError: true);
                          return;
                        }

                        // Server memeriksa kata sandi saat ini & aturan kekuatan
                        // (sama dengan halaman /profil web).
                        final messenger = ScaffoldMessenger.of(ctx);
                        final error = await ref.read(authNotifierProvider.notifier).changePassword(
                              currentPassword: current,
                              newPassword: next,
                              confirmation: confirm,
                            );

                        if (!ctx.mounted) return;

                        if (error == null) {
                          Navigator.pop(ctx);
                          AppHaptics.success();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi berhasil diperbarui!'),
                              backgroundColor: AppColors.mint,
                            ),
                          );
                        } else {
                          AppHaptics.error();
                          messenger.showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: AppColors.danger),
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
                      onPressed: () async {
                        final val = phoneController.text.trim();
                        final user = ref.read(authNotifierProvider).user;
                        final messenger = ScaffoldMessenger.of(ctx);

                        // Nomor divalidasi backend (`Phone::isValid`) — sama
                        // dengan form profil web, jadi format apa pun yang sah
                        // diterima tanpa aturan ganda di klien.
                        final error = await ref.read(authNotifierProvider.notifier).updateProfile(
                              name: user?.name ?? '',
                              phone: val,
                              institutionName: user?.institutionName,
                            );

                        if (!ctx.mounted) return;

                        if (error == null) {
                          Navigator.pop(ctx);
                          AppHaptics.success();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Nomor WhatsApp berhasil diperbarui!'),
                              backgroundColor: AppColors.mint,
                            ),
                          );
                        } else {
                          AppHaptics.error();
                          messenger.showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: AppColors.danger),
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
                    await _handleAvatarPick(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.mintText),
                  title: Text('Pilih dari Galeri', style: AppTypography.titleSmall),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _handleAvatarPick(ImageSource.gallery);
                  },
                ),
                // Hapus foto hanya relevan bila pengguna sudah punya foto.
                if (ref.read(authNotifierProvider).user?.avatarUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    title: Text(
                      'Hapus Foto Profil',
                      style: AppTypography.titleSmall.copyWith(color: AppColors.danger),
                    ),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      Navigator.pop(ctx);

                      final error =
                          await ref.read(authNotifierProvider.notifier).removeAvatar();
                      if (!mounted) return;

                      if (error == null) {
                        AppHaptics.success();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Foto profil dihapus.'),
                            backgroundColor: AppColors.mint,
                          ),
                        );
                      } else {
                        AppHaptics.error();
                        messenger.showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
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
    final permission = ref.watch(notificationPermissionProvider);
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
            // 1. Kartu identitas utama: avatar, prodi/angkatan, NIM, status akun.
            ProfileHeroCard(
              user: user,
              onAvatarTap: _showChangeAvatarSheet,
            ),
            const SizedBox(height: 18),

            // 3. Banner Pintu Masuk Panitia Hari-H (Hanya Muncul untuk Admin / Panitia)
            if (user.canScanTickets) ...[
              GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  // Banner membuka panel panitia (dashboard + verifikasi +
                  // peserta + scan), bukan langsung ke scanner.
                  context.push(AppRoutes.panitia);
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
                    leading: const Icon(Icons.notifications_active_rounded, color: AppColors.cobalt),
                    title: Text('Notifikasi', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    subtitle: Text(
                      permission.granted
                          ? 'Aktif — kabar tiket & acara muncul di layar HP'
                          : 'Nonaktif — aktifkan agar tidak ketinggalan kabar',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.ink500,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: permission.granted,
                      activeColor: AppColors.cobalt,
                      onChanged: (value) async {
                        final messenger = ScaffoldMessenger.of(context);

                        if (value) {
                          final granted =
                              await ref.read(notificationPermissionProvider.notifier).request();
                          if (!mounted) return;
                          AppHaptics.light();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                granted
                                    ? 'Notifikasi aktif.'
                                    : 'Izin ditolak sistem. Aktifkan lewat Pengaturan HP → Aplikasi → TemuKampus.',
                              ),
                              backgroundColor: granted ? AppColors.mint : AppColors.danger,
                            ),
                          );
                        } else {
                          // Menonaktifkan dari sisi aplikasi: berhenti menampilkan
                          // notifikasi sistem tanpa mencabut izin OS.
                          await NotificationService.instance.rememberDeclined();
                          await ref.read(notificationPermissionProvider.notifier).decline();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Notifikasi dinonaktifkan.')),
                          );
                        }
                      },
                    ),
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
