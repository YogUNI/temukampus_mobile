import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../../events/presentation/controllers/event_detail_controller.dart';
import '../controllers/registration_controller.dart';
import '../widgets/registration_event_summary.dart';
import '../widgets/registration_participant_card.dart';
import '../widgets/registration_payment_card.dart';
import '../widgets/registration_proof_upload_card.dart';
import '../widgets/registration_submit_bar.dart';
import '../widgets/registration_terms_card.dart';

/// Formulir pendaftaran acara (gratis maupun berbayar manual).
///
/// Struktur: ringkasan acara → data peserta → instruksi pembayaran (hero kode
/// unik) → unggah bukti → persetujuan. Aksi kirim berada di sticky bar bawah,
/// di dalam thumb zone.
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

  Future<void> _submit(bool isPaid) async {
    AppHaptics.selection();
    final success = await ref
        .read(registrationControllerProvider(widget.slug).notifier)
        .submit(isPaid: isPaid);
    if (success && mounted) {
      final result = ref.read(registrationControllerProvider(widget.slug)).result;
      _showSuccessDialog(result?.ticketCode ?? 'TK-SUCCESS', isPaid);
    }
  }

  void _openImageSourceSheet() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                Text('Unggah Bukti Pembayaran', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pilih sumber foto bukti transfer bank / m-banking Anda:',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.cobaltLight,
                      borderRadius: AppRadii.borderXs,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.cobalt),
                  ),
                  title: Text('Kamera Ponsel', style: AppTypography.titleSmall),
                  subtitle: Text(
                    'Ambil foto langsung dari struk fisik',
                    style: AppTypography.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(registrationControllerProvider(widget.slug).notifier)
                        .pickProof(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: AppRadii.borderXs,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.mintText),
                  ),
                  title: Text('Galeri Ponsel', style: AppTypography.titleSmall),
                  subtitle: Text(
                    'Pilih tangkapan layar (screenshot) transfer m-banking',
                    style: AppTypography.bodySmall,
                  ),
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

  void _showProofFullScreen(Uint8List bytes, String fileName) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: AppRadii.borderMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pratinjau Bukti: $fileName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
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
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadii.md),
                    ),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadii.md),
                    ),
                  ),
                  child: Text(
                    'Cubit / zoom foto untuk memeriksa kejelasan struk',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.ink500,
                    ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.sheetTop,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mint, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: AppColors.mintText, size: 44),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pendaftaran Berhasil Dikirim!',
                  style: AppTypography.hero.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isPaid
                      ? 'Panitia akan memverifikasi bukti transfermu maksimal 1x24 jam.'
                      : 'Selamat! Pendaftaranmu terkonfirmasi otomatis.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: AppSpacing.xl),
                TicketContainer(
                  punchRadius: 10,
                  punchPositionPercent: 0.5,
                  borderRadius: 14,
                  borderColor: AppColors.ink,
                  borderWidth: 1.4,
                  hasShadow: true,
                  shadowOffset: const Offset(2.5, 2.5),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KODE TIKET RESMI',
                              style: AppTypography.micro.copyWith(
                                color: AppColors.ink400,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid ? AppColors.amberLight : AppColors.mintLight,
                            borderRadius: AppRadii.borderXs,
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
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    label: 'Lihat Tiket Saya',
                    variant: StickerButtonVariant.primary,
                    icon: const Icon(
                      Icons.confirmation_number_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.ticketDetailPath(ticketCode));
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
    final canSubmit = regState.canSubmit(isPaid: isPaid);

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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegistrationEventSummary(event: event),
            const SizedBox(height: AppSpacing.xl),

            Text('Data Peserta (Otomatis Terisi)', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            RegistrationParticipantCard(user: user),
            const SizedBox(height: AppSpacing.xxl),

            if (isPaid) ...[
              RegistrationPaymentCard(
                preview: regState.paymentPreview,
                event: event,
                onCopy: _copyToClipboard,
              ),
              const SizedBox(height: AppSpacing.xl),
              RegistrationProofUploadCard(
                selectedProof: regState.selectedProof,
                isCompressing: regState.isCompressing,
                onPick: _openImageSourceSheet,
                onPreview: _showProofFullScreen,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],

            RegistrationTermsCard(
              termsAccepted: regState.termsAccepted,
              errorMessage: regState.errorMessage,
              onTermsChanged: (value) => ref
                  .read(registrationControllerProvider(widget.slug).notifier)
                  .toggleTerms(value),
            ),

            // Ruang agar konten terakhir tidak tertutup sticky bar
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: RegistrationSubmitBar(
        isPaid: isPaid,
        isSubmitting: regState.isSubmitting,
        canSubmit: canSubmit,
        totalText: regState.paymentPreview?.formattedTotal ?? 'Rp 25.137',
        onPressed: () => _submit(isPaid),
      ),
    );
  }
}
