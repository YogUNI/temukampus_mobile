import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../../events/presentation/controllers/event_detail_controller.dart';
import '../controllers/registration_controller.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String slug;

  const RegistrationScreen({super.key, required this.slug});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detailState = ref.read(eventDetailControllerProvider(widget.slug));
      final isPaid = detailState.detail?.event.isPaid ?? false;
      ref
          .read(registrationControllerProvider(widget.slug).notifier)
          .loadPaymentPreview(isPaid: isPaid);
    });
  }

  void _copyToClipboard(String text, String message) {
    AppHaptics.selection();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openImageSourceSheet() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                Text('Unggah Bukti Pembayaran', style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Pilih sumber foto bukti transfer bank / m-banking Anda:',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.cobalt),
                  ),
                  title: Text('Kamera Ponsel', style: AppTypography.titleSmall),
                  subtitle: Text('Ambil foto langsung dari struk fisik', style: AppTypography.bodySmall),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(registrationControllerProvider(widget.slug).notifier)
                        .pickProof(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.mintText),
                  ),
                  title: Text('Galeri Ponsel', style: AppTypography.titleSmall),
                  subtitle: Text('Pilih tangkapan layar (screenshot) transfer m-banking', style: AppTypography.bodySmall),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(registrationControllerProvider(widget.slug).notifier)
                        .pickProof(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProofFullScreen(BuildContext context, Uint8List bytes, String fileName) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, offset: Offset(0, 8), blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Pratinjau Bukti: $fileName',
                          style: AppTypography.titleSmall.copyWith(color: Colors.white, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.ink700, height: 1),
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  child: Text(
                    'Cubit / Zoom foto untuk memeriksa kejelasan tulisan struk',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String ticketCode, bool isPaid) {
    AppHaptics.success();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animasi / Ikon Centang Hijau Besar Motif Selebrasi
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mint, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: AppColors.mintText, size: 44),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pendaftaran Berhasil Dikirim!',
                  style: AppTypography.hero.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isPaid
                      ? 'Panitia akan memverifikasi bukti transfermu maksimal 1x24 jam.'
                      : 'Selamat! Pendaftaranmu terkonfirmasi otomatis.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: 20),

                // Kartu Tiket Notch Motif
                TicketContainer(
                  punchRadius: 10.0,
                  punchPositionPercent: 0.5,
                  borderRadius: 14.0,
                  borderColor: AppColors.ink,
                  borderWidth: 1.4,
                  hasShadow: true,
                  shadowOffset: const Offset(2.5, 2.5),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KODE TIKET RESMI',
                              style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.ink400),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticketCode,
                              style: AppTypography.numericCode.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cobalt,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPaid ? AppColors.amberLight : AppColors.mintLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isPaid ? AppColors.amber : AppColors.mint,
                            ),
                          ),
                          child: Text(
                            isPaid ? 'MENUNGGU VERIFIKASI' : 'TERKONFIRMASI',
                            style: AppTypography.badge.copyWith(
                              color: isPaid ? AppColors.warningText : AppColors.mintText,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dua Tombol Aksi Jelas
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    label: 'Lihat Tiket Saya',
                    variant: StickerButtonVariant.primary,
                    icon: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 18),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.ticketDetailPath(ticketCode));
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    label: 'Kembali ke Beranda',
                    variant: StickerButtonVariant.outline,
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.home);
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

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(eventDetailControllerProvider(widget.slug));
    final regState = ref.watch(registrationControllerProvider(widget.slug));
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final event = detailState.detail?.event;
    final isPaid = event?.isPaid ?? false;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Formulir Pendaftaran', style: AppTypography.titleMedium),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () {
            AppHaptics.light();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.eventDetailPath(widget.slug));
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ringkasan Singkat Acara
            if (event != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ink200, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cobaltLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.event_note_rounded, color: AppColors.cobalt, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: AppTypography.titleSmall.copyWith(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppFormatters.eventDate(event.startAt)} • ${event.formatLabel}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 2. Data Peserta Otomatis (Read-Only)
            Text('Data Peserta (Otomatis Terisi)', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.ink, width: 1.2),
                boxShadow: const [
                  BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5), blurRadius: 0),
                ],
              ),
              child: Column(
                children: [
                  _buildDataRow(Icons.person_outline_rounded, 'Nama Lengkap', user?.name ?? '-'),
                  const Divider(height: 18),
                  _buildDataRow(Icons.badge_outlined, 'NIM Mahasiswa', user?.nim ?? 'Peserta Eksternal'),
                  const Divider(height: 18),
                  _buildDataRow(Icons.school_outlined, 'Program Studi & Angkatan', user?.academicSummary ?? '-'),
                  const Divider(height: 18),
                  _buildDataRow(Icons.phone_android_rounded, 'Nomor WhatsApp', user?.phone ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Bagian Pembayaran Manual & Kode Unik 3 Digit (Khusus Acara Berbayar)
            if (isPaid) ...[
              Text('Instruksi Transfer Pembayaran', style: AppTypography.titleSmall),
              const SizedBox(height: 8),

              // Rincian Biaya & Kode Unik Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Harga Tiket', style: AppTypography.bodySmall),
                        Text(
                          regState.paymentPreview != null
                              ? AppFormatters.rupiah(regState.paymentPreview!.ticketPrice)
                              : event?.formattedPrice ?? 'Rp 25.000',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Kode Unik Transfer', style: AppTypography.bodySmall),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.signalLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '3 DIGIT',
                                style: AppTypography.badge.copyWith(color: AppColors.ink, fontSize: 8),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          regState.paymentPreview != null
                              ? '+ Rp ${regState.paymentPreview!.uniqueCode}'
                              : '+ Rp 137',
                          style: AppTypography.numericCode.copyWith(
                            color: AppColors.signal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Total Wajib Ditransfer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL DITRANSFER', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.ink500)),
                            const SizedBox(height: 2),
                            Text(
                              regState.paymentPreview?.formattedTotal ?? 'Rp 25.137',
                              style: AppTypography.hero.copyWith(fontSize: 20, color: AppColors.cobalt),
                            ),
                          ],
                        ),
                        StickerButton(
                          label: 'Salin',
                          fullWidth: false,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          variant: StickerButtonVariant.outline,
                          icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.ink),
                          onPressed: () {
                            final nominal = regState.paymentPreview?.totalAmountDue.toString() ?? '25137';
                            _copyToClipboard(nominal, 'Nominal berhasil disalin!');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Warning Alert
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PENTING: Transfer tepat sampai 3 digit terakhir agar pembayaran dapat diverifikasi otomatis oleh sistem.',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rekening Tujuan Panitia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.ink200, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rekening Tujuan Panitia', style: AppTypography.labelSmall.copyWith(color: AppColors.ink500)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              regState.paymentPreview?.bankName ?? event?.bankName ?? 'BCA (Bank Central Asia)',
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              regState.paymentPreview?.accountNumber ?? event?.bankAccountNumber ?? '5410982311',
                              style: AppTypography.numericCode.copyWith(fontSize: 16, color: AppColors.ink),
                            ),
                            Text(
                              'a.n. ${regState.paymentPreview?.accountName ?? event?.bankAccountName ?? "PANITIA ACARA"}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.cobalt),
                          onPressed: () {
                            final acc = regState.paymentPreview?.accountNumber ?? event?.bankAccountNumber ?? '5410982311';
                            _copyToClipboard(acc, 'Nomor rekening berhasil disalin!');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Upload Bukti Pembayaran
              Text('Unggah Bukti Transfer', style: AppTypography.titleSmall),
              const SizedBox(height: 8),

              if (regState.selectedProof == null) ...[
                GestureDetector(
                  onTap: _openImageSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.ink200, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.cobaltLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: AppColors.cobalt, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text('Klik untuk Pilih Bukti Transfer', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Kamera langsung atau galeri foto (JPG/PNG, otomatis dikompresi < 2 MB)',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Thumbnail Pratinjau Bukti Terpilih
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.mint, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showProofFullScreen(
                          context,
                          regState.selectedProof!.bytes,
                          regState.selectedProof!.fileName,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                regState.selectedProof!.bytes,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showProofFullScreen(
                            context,
                            regState.selectedProof!.bytes,
                            regState.selectedProof!.fileName,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Bukti Siap Diunggah',
                                    style: AppTypography.titleSmall.copyWith(color: AppColors.mintText, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                regState.selectedProof!.fileName,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${regState.selectedProof!.formattedSize} • Ketuk untuk perbesar',
                                style: AppTypography.numericCode.copyWith(fontSize: 10, color: AppColors.cobalt),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openImageSourceSheet,
                        child: Text('Ganti', style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // 4. Checkbox Persetujuan Syarat & Privasi
            GestureDetector(
              onTap: () {
                ref
                    .read(registrationControllerProvider(widget.slug).notifier)
                    .toggleTerms(!regState.termsAccepted);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: regState.termsAccepted,
                    activeColor: AppColors.cobalt,
                    onChanged: (val) {
                      ref
                          .read(registrationControllerProvider(widget.slug).notifier)
                          .toggleTerms(val);
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Saya menyetujui data diri saya digunakan oleh panitia pelaksana untuk keperluan registrasi dan penerbitan tiket kegiatan ini.',
                        style: AppTypography.bodySmall.copyWith(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Error Notice jika ada
            if (regState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        regState.errorMessage!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 5. Tombol Kirim Pendaftaran
            SizedBox(
              width: double.infinity,
              child: StickerButton(
                label: regState.isSubmitting
                    ? 'Mengirim Pendaftaran...'
                    : (isPaid ? 'Kirim Pendaftaran & Bukti Bayar' : 'Konfirmasi Pendaftaran Gratis'),
                variant: StickerButtonVariant.primary,
                isLoading: regState.isSubmitting,
                onPressed: regState.canSubmit(isPaid: isPaid)
                    ? () async {
                        AppHaptics.selection();
                        final success = await ref
                            .read(registrationControllerProvider(widget.slug).notifier)
                            .submit(isPaid: isPaid);
                        if (success && mounted) {
                          final result = ref.read(registrationControllerProvider(widget.slug)).result;
                          _showSuccessDialog(result?.ticketCode ?? 'TK-SUCCESS', isPaid);
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.cobalt),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.ink500)),
              const SizedBox(height: 1),
              Text(value, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
