import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../data/models/event_model.dart';
import '../controllers/event_detail_controller.dart';

class EventDetailScreen extends ConsumerWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(eventDetailControllerProvider(slug));
    final authState = ref.watch(authNotifierProvider);

    if (detailState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cobalt),
        ),
      );
    }

    if (detailState.errorMessage != null || detailState.detail == null) {
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
                const SizedBox(height: 14),
                Text(
                  detailState.errorMessage ?? 'Acara tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(eventDetailControllerProvider(slug).notifier).loadDetail(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final detail = detailState.detail!;
    final event = detail.event;
    final eligibility = detailState.eligibility;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Content Scroll
          CustomScrollView(
            slivers: [
              // 1. Poster Header with Gradient
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.ink,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.ink, size: 18),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tautan acara "${event.title}" disalin!')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppColors.ink800,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_rounded,
                          color: AppColors.ink400,
                          size: 64,
                        ),
                      ),
                      // Gradient Overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Info Acara Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Organisasi Penyelenggara
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.cobaltLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.groups_rounded, color: AppColors.cobalt, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Penyelenggara', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                                Text(
                                  event.organization.name,
                                  style: AppTypography.titleSmall.copyWith(fontSize: 13, color: AppColors.cobalt),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.ink100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.formatLabel,
                              style: AppTypography.badge.copyWith(color: AppColors.ink700, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Judul Acara
                      Text(event.title, style: AppTypography.hero.copyWith(fontSize: 22)),
                      const SizedBox(height: 14),

                      // Badges Bar
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailBadge(
                            label: event.isFree ? 'Gratis' : event.formattedPrice,
                            color: event.isFree ? AppColors.mintText : AppColors.cobalt,
                            bgColor: event.isFree ? AppColors.mintLight : AppColors.cobaltLight,
                          ),
                          if (event.hasSkp)
                            _buildDetailBadge(
                              label: '${event.skpPoints} Poin SKP',
                              color: AppColors.cobalt,
                              bgColor: AppColors.cobaltLight,
                            ),
                          if (event.hasCertificate)
                            _buildDetailBadge(
                              label: 'E-Sertifikat',
                              color: AppColors.mintText,
                              bgColor: AppColors.mintLight,
                            ),
                          _buildDetailBadge(
                            label: event.audience == 'umb_only'
                                ? 'Khusus Mahasiswa UMB'
                                : (event.audience == 'restricted' ? 'Terbatas Jurusan' : 'Terbuka Umum'),
                            color: AppColors.ink700,
                            bgColor: AppColors.ink100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Jadwal & Lokasi Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.ink200, width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: AppColors.ink, offset: Offset(2, 2), blurRadius: 0),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppColors.cobalt, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tanggal & Waktu', style: AppTypography.labelSmall.copyWith(fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${AppFormatters.eventDate(event.startAt)} • ${AppFormatters.eventTime(event.startAt)}',
                                        style: AppTypography.titleSmall.copyWith(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.cobalt, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Lokasi Pelaksanaan', style: AppTypography.labelSmall.copyWith(fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        event.location,
                                        style: AppTypography.titleSmall.copyWith(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informasi Sisa Kuota Bar
                      if (event.quota != null) ...[
                        _buildQuotaProgress(event),
                        const SizedBox(height: 20),
                      ],

                      // Syarat Program Studi & Angkatan
                      if (detail.allowedStudyPrograms.isNotEmpty || detail.minCohortYear != null) ...[
                        _buildEligibilityTermsCard(detail),
                        const SizedBox(height: 20),
                      ],

                      // Deskripsi Kegiatan (Markdown Render)
                      Text('Tentang Kegiatan', style: AppTypography.titleMedium),
                      const SizedBox(height: 10),
                      Text(
                        detail.description,
                        style: AppTypography.bodyMedium.copyWith(height: 1.6, color: AppColors.ink),
                      ),
                      const SizedBox(height: 24),

                      // Tata Tertib
                      if (detail.terms != null && detail.terms!.isNotEmpty) ...[
                        Text('Tata Tertib & Ketentuan', style: AppTypography.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          detail.terms!,
                          style: AppTypography.bodyMedium.copyWith(height: 1.5, color: AppColors.ink500),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Spacer agar konten tidak tertutup Sticky Bottom Bar
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. STICKY BOTTOM ACTION BAR (11 CTA States)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(
              context: context,
              event: event,
              eligibility: eligibility,
              isLoggedIn: authState.isAuthenticated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTypography.badge.copyWith(color: color)),
    );
  }

  Widget _buildQuotaProgress(EventModel event) {
    final quota = event.quota ?? 100;
    final remaining = event.remainingQuota ?? 0;
    final filled = quota - remaining;
    final progress = (filled / quota).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ketersediaan Kuota', style: AppTypography.labelSmall),
              Text(
                event.isFull ? 'Kuota Penuh' : 'Tersisa $remaining dari $quota Tiket',
                style: AppTypography.labelSmall.copyWith(
                  color: event.isFull ? AppColors.dangerText : AppColors.cobalt,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.ink100,
              valueColor: AlwaysStoppedAnimation<Color>(
                event.isFull
                    ? AppColors.danger
                    : (event.isQuotaAlmostFull ? AppColors.signal : AppColors.cobalt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityTermsCard(EventDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cobaltLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.cobalt, size: 16),
              const SizedBox(width: 6),
              Text(
                'Syarat Kelayakan Peserta',
                style: AppTypography.titleSmall.copyWith(color: AppColors.cobalt, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (detail.allowedStudyPrograms.isNotEmpty)
            Text(
              '• Program Studi: ${detail.allowedStudyPrograms.join(", ")}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink700),
            ),
          if (detail.minCohortYear != null && detail.maxCohortYear != null)
            Text(
              '• Angkatan: ${detail.minCohortYear} – ${detail.maxCohortYear}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink700),
            ),
        ],
      ),
    );
  }

  /// STICKY BOTTOM ACTION BAR DENGAN 11 STATUS CTA
  Widget _buildBottomActionBar({
    required BuildContext context,
    required EventModel event,
    required EligibilityResultModel? eligibility,
    required bool isLoggedIn,
  }) {
    final ctaState = eligibility?.ctaState ??
        (!isLoggedIn
            ? EventCtaState.notLoggedIn
            : (event.isFull ? EventCtaState.quotaFull : EventCtaState.canRegister));

    Widget actionWidget;

    switch (ctaState) {
      case EventCtaState.eventCancelled:
        actionWidget = Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.danger),
          ),
          child: Text('Acara Ini Telah Dibatalkan', style: AppTypography.titleSmall.copyWith(color: AppColors.dangerText)),
        );
        break;

      case EventCtaState.eventEnded:
        actionWidget = StickerButton(
          label: 'Pendaftaran Ditutup (Acara Selesai)',
          variant: StickerButtonVariant.outline,
          onPressed: null,
        );
        break;

      case EventCtaState.notLoggedIn:
        actionWidget = StickerButton(
          label: 'Masuk untuk Mendaftar',
          variant: StickerButtonVariant.primary,
          onPressed: () => context.push(AppRoutes.login),
        );
        break;

      case EventCtaState.emailUnverified:
        actionWidget = StickerButton(
          label: 'Verifikasi Email Terlebih Dahulu',
          variant: StickerButtonVariant.secondary,
          onPressed: () => context.push(AppRoutes.verifyEmail),
        );
        break;

      case EventCtaState.profileIncomplete:
        actionWidget = StickerButton(
          label: 'Lengkapi Profil (No. WhatsApp)',
          variant: StickerButtonVariant.secondary,
          onPressed: () => context.push(AppRoutes.profile),
        );
        break;

      case EventCtaState.alreadyRegistered:
        actionWidget = StickerButton(
          label: 'Lihat Tiket Saya',
          variant: StickerButtonVariant.primary,
          icon: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 18),
          onPressed: () => context.go(AppRoutes.myTickets),
        );
        break;

      case EventCtaState.notEligible:
        final reason = eligibility?.reasons.isNotEmpty == true
            ? eligibility!.reasons.first
            : 'Acara ini tidak terbuka untuk prodi atau angkatan Anda.';
        actionWidget = Column(
          children: [
            Text(reason, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText)),
            const SizedBox(height: 8),
            StickerButton(
              label: 'Syarat Tidak Cocok',
              variant: StickerButtonVariant.outline,
              onPressed: null,
            ),
          ],
        );
        break;

      case EventCtaState.notOpenYet:
        actionWidget = StickerButton(
          label: 'Pendaftaran Belum Dibuka',
          variant: StickerButtonVariant.outline,
          onPressed: null,
        );
        break;

      case EventCtaState.registrationClosed:
        actionWidget = StickerButton(
          label: 'Pendaftaran Ditutup',
          variant: StickerButtonVariant.outline,
          onPressed: null,
        );
        break;

      case EventCtaState.quotaFull:
        actionWidget = StickerButton(
          label: 'Kuota Penuh',
          variant: StickerButtonVariant.danger,
          onPressed: null,
        );
        break;

      case EventCtaState.canRegister:
        actionWidget = StickerButton(
          label: event.isFree ? 'Daftar Sekarang (Gratis)' : 'Daftar & Bayar (${event.formattedPrice})',
          variant: StickerButtonVariant.primary,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Formulir pendaftaran dan pembayaran manual akan dibuka di Tahap 4!'),
                backgroundColor: AppColors.cobalt,
              ),
            );
          },
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.ink100, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            offset: const Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(child: actionWidget),
    );
  }
}
