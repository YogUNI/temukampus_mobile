import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../controllers/ticket_detail_controller.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketCode;

  const TicketDetailScreen({super.key, required this.ticketCode});

  void _copyToClipboard(BuildContext context, String text, String message) {
    AppHaptics.selection();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.ink),
    );
  }

  Future<void> _openUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    AppHaptics.selection();
    try {
      final uri = Uri.parse(urlString);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka tautan.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan tidak valid.')),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          title: Text('Batalkan Pendaftaran?', style: AppTypography.titleMedium),
          content: Text(
            'Apakah Anda yakin ingin membatalkan pendaftaran tiket ini? Kuota akan dilepaskan kembali ke peserta lain.',
            style: AppTypography.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref
                    .read(ticketDetailControllerProvider(ticketCode).notifier)
                    .cancelTicket();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pendaftaran tiket berhasil dibatalkan.')),
                  );
                }
              },
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );
  }

  void _showResubmitSheet(BuildContext context, WidgetRef ref) {
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
                Text('Unggah Ulang Bukti Transfer', style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Pastikan nomor referensi transfer dan tanggal terlihat jelas.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.cobalt),
                  title: Text('Kamera Langsung', style: AppTypography.titleSmall),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final data = await AppImageHelper.pickImage(ImageSource.camera);
                    if (data != null) {
                      await ref
                          .read(ticketDetailControllerProvider(ticketCode).notifier)
                          .resubmitProof(data);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.mintText),
                  title: Text('Galeri Ponsel', style: AppTypography.titleSmall),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final data = await AppImageHelper.pickImage(ImageSource.gallery);
                    if (data != null) {
                      await ref
                          .read(ticketDetailControllerProvider(ticketCode).notifier)
                          .resubmitProof(data);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(ticketDetailControllerProvider(ticketCode));

    if (detailState.isLoading && detailState.ticket == null) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator(color: AppColors.cobalt)),
      );
    }

    if (detailState.ticket == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  detailState.errorMessage ?? 'Tiket tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(ticketDetailControllerProvider(ticketCode).notifier)
                      .loadDetail(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ticket = detailState.ticket!;
    RegistrationStatusType statusType;
    switch (ticket.status) {
      case 'confirmed':
        statusType = RegistrationStatusType.confirmed;
        break;
      case 'needs_revision':
        statusType = RegistrationStatusType.needsRevision;
        break;
      case 'cancelled':
        statusType = RegistrationStatusType.cancelled;
        break;
      case 'rejected':
        statusType = RegistrationStatusType.rejected;
        break;
      case 'pending_verification':
      default:
        statusType = RegistrationStatusType.pendingVerification;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Tiket Digital', style: AppTypography.titleMedium),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () {
            AppHaptics.light();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.myTickets);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // KARTU TIKET LENGKAP MOTIF FISIK
            TicketContainer(
              punchRadius: 16.0,
              punchPositionPercent: 0.58,
              borderRadius: 20.0,
              borderColor: AppColors.ink,
              borderWidth: 1.6,
              hasShadow: true,
              shadowOffset: const Offset(4, 4),
              child: Column(
                children: [
                  // 1. BAGIAN ATAS: QR CODE & KODE TIKET
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Header: Ormawa & Cap Stempel Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TEMUKAMPUS PASS', style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 11)),
                            StatusPill(status: statusType, isStamp: true),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // QR CODE WIDGET
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.ink, width: 1.6),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.ink,
                                offset: Offset(2.5, 2.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: ticket.ticketCode,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.ink,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // KODE TIKET MONOSPACED
                        GestureDetector(
                          onTap: () => _copyToClipboard(context, ticket.ticketCode, 'Kode tiket disalin!'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ticket.ticketCode,
                                style: AppTypography.hero.copyWith(
                                  fontSize: 22,
                                  letterSpacing: 2.0,
                                  color: AppColors.cobalt,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy_rounded, size: 16, color: AppColors.ink500),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Kotak Petunjuk QR Hari-H
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: ticket.isCheckedIn ? AppColors.mintLight : AppColors.paper,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ticket.isCheckedIn ? AppColors.mint : AppColors.ink200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ticket.isCheckedIn ? Icons.verified_rounded : Icons.info_outline_rounded,
                                size: 16,
                                color: ticket.isCheckedIn ? AppColors.mintText : AppColors.ink500,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  ticket.isCheckedIn
                                      ? 'Presensi Masuk Berhasil: ${AppFormatters.eventTime(ticket.checkedInAt!)}'
                                      : 'Tunjukkan QR Code ini ke panitia di meja registrasi saat hari-H.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: ticket.isCheckedIn ? AppColors.mintText : AppColors.ink700,
                                    fontWeight: ticket.isCheckedIn ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. PERFORASI SOBEKAN
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: DottedTearLine(color: AppColors.ink200),
                  ),

                  // 3. BAGIAN BAWAH: RINCIAN ACARA & PESERTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ticket.event.posterUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppNetworkOrAssetImage(
                                  imagePath: ticket.event.posterUrl,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                ticket.event.title,
                                style: AppTypography.titleMedium.copyWith(fontSize: 15.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Jadwal & Lokasi
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.cobalt),
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.eventDate(ticket.event.startAt),
                              style: AppTypography.bodySmall.copyWith(fontSize: 12),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.cobalt),
                            const SizedBox(width: 4),
                            Text(
                              AppFormatters.eventTime(ticket.event.startAt),
                              style: AppTypography.bodySmall.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.cobalt),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ticket.event.location,
                                style: AppTypography.bodySmall.copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Profil Peserta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NAMA PESERTA', style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.ink400)),
                                Text(ticket.participant.name, style: AppTypography.titleSmall.copyWith(fontSize: 13)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('NIM MAHASISWA', style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.ink400)),
                                Text(ticket.participant.nim ?? '-', style: AppTypography.numericCode.copyWith(fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. KOTAK PERINGATAN REVISI (Jika status needs_revision)
            if (ticket.isNeedsRevision) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.signalLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.signal, width: 1.6),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.signal, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Bukti Pembayaran Perlu Revisi',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.ink, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.revisionNotes ?? 'Bukti pembayaran tidak terbaca. Mohon unggah bukti baru yang jelas.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.ink, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: StickerButton(
                        label: 'Unggah Ulang Bukti Bayar',
                        variant: StickerButtonVariant.secondary,
                        icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.ink, size: 16),
                        onPressed: () => _showResubmitSheet(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 5. AKSES KHUSUS PESERTA TERKONFIRMASI (BR-13)
            if (ticket.isConfirmed && ticket.unlockedAccess.canAccessLinks) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.mint, width: 1.4),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_open_rounded, color: AppColors.mint, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Akses Khusus Peserta Terkonfirmasi',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.mintText, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (ticket.unlockedAccess.waGroupUrl != null) ...[
                      GestureDetector(
                        onTap: () => _openUrl(context, ticket.unlockedAccess.waGroupUrl),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366), // Hijau Resmi WhatsApp
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.ink, width: 1.4),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.ink,
                                offset: Offset(2.5, 2.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Gabung Grup WhatsApp Peserta',
                                style: AppTypography.label.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (ticket.unlockedAccess.meetingUrl != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: StickerButton(
                          label: 'Buka Tautan Zoom / Google Meet',
                          variant: StickerButtonVariant.outline,
                          icon: const Icon(Icons.videocam_outlined, color: AppColors.ink, size: 16),
                          onPressed: () => _openUrl(context, ticket.unlockedAccess.meetingUrl),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 6. BATALKAN PENDAFTARAN (Jika belum check-in & belum cancelled)
            if (!ticket.isCheckedIn && !ticket.isCancelled) ...[
              TextButton(
                onPressed: () => _showCancelDialog(context, ref),
                child: Text(
                  'Batalkan Pendaftaran Tiket',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.dangerText),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
