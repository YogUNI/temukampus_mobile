import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../data/models/ticket_model.dart';
import '../controllers/ticket_detail_controller.dart';
import '../widgets/ticket_pass_card.dart';

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
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan tidak valid.')),
        );
      }
    }
  }

  void _shareTicket(BuildContext context, TicketModel ticket) {
    AppHaptics.selection();
    try {
      SharePlus.instance.share(
        ShareParams(
          text: 'Tiket TemuKampus ${ticket.ticketCode} — "${ticket.event.title}"\n'
              '${AppFormatters.eventDate(ticket.event.startAt)} · '
              '${AppFormatters.eventTime(ticket.event.startAt)}\n'
              '${ticket.event.location}',
          subject: 'Tiket ${ticket.event.title}',
        ),
      );
    } catch (_) {
      _copyToClipboard(context, ticket.ticketCode, 'Kode tiket berhasil disalin!');
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          title: Text('Batalkan Pendaftaran?', style: AppTypography.titleMedium),
          content: Text(
            'Apakah Anda yakin ingin membatalkan pendaftaran tiket ini? '
            'Kuota akan dilepaskan kembali ke peserta lain.',
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
                    const SnackBar(
                      content: Text('Pendaftaran tiket berhasil dibatalkan.'),
                    ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.sheetTop,
          ),
          child: SafeArea(
            top: false,
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
                      borderRadius: AppRadii.borderPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Unggah Ulang Bukti Transfer', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pastikan nomor referensi transfer dan tanggal terlihat jelas.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                  contentPadding: EdgeInsets.zero,
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

  RegistrationStatusType _statusTypeOf(TicketModel ticket) {
    switch (ticket.status) {
      case 'confirmed':
        return RegistrationStatusType.confirmed;
      case 'needs_revision':
        return RegistrationStatusType.needsRevision;
      case 'cancelled':
        return RegistrationStatusType.cancelled;
      case 'rejected':
        return RegistrationStatusType.rejected;
      case 'pending_verification':
      default:
        return RegistrationStatusType.pendingVerification;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(ticketDetailControllerProvider(ticketCode));

    if (detailState.isLoading && detailState.ticket == null) {
      return const _TicketDetailSkeleton();
    }

    if (detailState.ticket == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.danger),
                const SizedBox(height: AppSpacing.md),
                Text(
                  detailState.errorMessage ?? 'Tiket tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
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
        actions: [
          IconButton(
            tooltip: 'Bagikan tiket',
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.ink),
            onPressed: () => _shareTicket(context, ticket),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TicketPassCard(
              ticket: ticket,
              statusType: _statusTypeOf(ticket),
              onCopyCode: () => _copyToClipboard(
                context,
                ticket.ticketCode,
                'Kode tiket berhasil disalin!',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Aksi utama: bagikan tiket
            SizedBox(
              width: double.infinity,
              child: StickerButton(
                label: 'Bagikan Tiket',
                variant: StickerButtonVariant.outline,
                icon: const Icon(Icons.share_rounded, color: AppColors.ink, size: 18),
                onPressed: () => _shareTicket(context, ticket),
              ),
            ),

            // === REVISI BUKTI (status needs_revision) ===
            if (ticket.isNeedsRevision) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.signalLight,
                  borderRadius: AppRadii.borderMd,
                  border: Border.all(color: AppColors.signal, width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.signal, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Bukti Pembayaran Perlu Revisi',
                          style: AppTypography.titleSmall.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ticket.revisionNotes ??
                          'Bukti pembayaran tidak terbaca. Mohon unggah bukti baru yang jelas.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: StickerButton(
                        label: 'Unggah Ulang Bukti Bayar',
                        variant: StickerButtonVariant.secondary,
                        icon: const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.ink, size: 16),
                        onPressed: () => _showResubmitSheet(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // === AKSES PESERTA TERKONFIRMASI (BR-13) ===
            if (ticket.isConfirmed && ticket.unlockedAccess.canAccessLinks) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.borderMd,
                  border: Border.all(color: AppColors.mint.withValues(alpha: 0.5)),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: AppColors.mint, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Akses Khusus Peserta Terkonfirmasi',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.mintText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ticket.unlockedAccess.waGroupUrl != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      GestureDetector(
                        onTap: () => _openUrl(context, ticket.unlockedAccess.waGroupUrl),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                            horizontal: AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: AppRadii.borderSm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Gabung Grup WhatsApp Peserta',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (ticket.unlockedAccess.meetingUrl != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: StickerButton(
                          label: 'Buka Tautan Zoom / Google Meet',
                          variant: StickerButtonVariant.outline,
                          icon: const Icon(Icons.videocam_outlined,
                              color: AppColors.ink, size: 16),
                          onPressed: () =>
                              _openUrl(context, ticket.unlockedAccess.meetingUrl),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // === BATALKAN ===
            if (!ticket.isCheckedIn && !ticket.isCancelled) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => _showCancelDialog(context, ref),
                  child: Text(
                    'Batalkan Pendaftaran Tiket',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.dangerText,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketDetailSkeleton extends StatelessWidget {
  const _TicketDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(elevation: 0),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          children: [
            Container(
              height: 520,
              decoration: BoxDecoration(
                color: AppColors.ink100,
                borderRadius: AppRadii.borderXl,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.ink100,
                borderRadius: AppRadii.borderSm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}