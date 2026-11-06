import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../data/models/event_model.dart';
import '../controllers/event_detail_controller.dart';
import '../widgets/quota_progress_bar.dart';

class EventDetailScreen extends ConsumerWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  void _showGuestLoginSheet(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
                const SizedBox(height: 18),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cobaltLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cobalt, width: 1.5),
                  ),
                  child: const Icon(Icons.login_rounded, color: AppColors.cobalt, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  'Masuk untuk Mendaftar',
                  style: AppTypography.titleMedium.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Untuk mendaftar acara "${event.title}", silakan masuk dengan akun mahasiswa UMB atau buat akun baru.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    label: 'Masuk Sekarang',
                    variant: StickerButtonVariant.primary,
                    onPressed: () {
                      Navigator.pop(ctx);
                      final encodedRedirect = Uri.encodeComponent(AppRoutes.eventRegisterPath(event.slug));
                      context.push('${AppRoutes.login}?redirect=$encodedRedirect&reason=register');
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
                      Navigator.pop(ctx);
                      context.push(AppRoutes.register);
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
                  onPressed: () {
                    AppHaptics.selection();
                    ref.read(eventDetailControllerProvider(slug).notifier).loadDetail();
                  },
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

    // Hitung status CTA menggunakan kalkulator 11-state ketat (PRD §7.4.1)
    final ctaResult = EventCtaCalculator.calculate(
      event: event,
      user: authState.user,
      hasActiveTicket: detail.hasUserRegistered,
      activeTicketCode: detail.userTicketCode,
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Content Scroll
          CustomScrollView(
            slivers: [
              // 1. Poster Header Full-Bleed with Gradient
              SliverAppBar(
                expandedHeight: 250,
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
                  onPressed: () {
                    AppHaptics.light();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
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
                      AppHaptics.light();
                      try {
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'Temukan acara "${event.title}" di TemuKampus Mobile (Universitas Mercu Buana)!\nhttp://temukampus.test/events/${event.slug}',
                            subject: event.title,
                          ),
                        );
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tautan acara "${event.title}" disalin!')),
                        );
                      }
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
                      // Gradient Overlay Atas & Bawah
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Badge Kategori di Pojok Kiri Bawah Poster
                      Positioned(
                        left: 20,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.signal,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.ink, width: 1.2),
                          ),
                          child: Text(
                            (event.category ?? 'Acara Kampus').toUpperCase(),
                            style: AppTypography.badge.copyWith(
                              color: AppColors.ink,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Body Detail Konten
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Mode Tamu jika belum login
                      if (authState.user == null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cobaltLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.cobalt, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Mode Tamu: Masuk dengan akun mahasiswa UMB untuk mendaftar & klaim tiket acara ini.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Ormawa Host & Format Badge
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.cobaltLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cobalt, width: 1.2),
                            ),
                            child: const Center(
                              child: Icon(Icons.groups_rounded, color: AppColors.cobalt, size: 18),
                            ),
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
                          border: Border.all(color: AppColors.ink, width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5), blurRadius: 0),
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

                      // Informasi Sisa Kuota Bar (QuotaProgressBar)
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
                        child: QuotaProgressBar(
                          quota: event.quota,
                          remainingQuota: event.remainingQuota,
                          registeredCount: event.registeredCount,
                          isFull: event.isFull,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Syarat Program Studi & Angkatan
                      if (detail.allowedStudyPrograms.isNotEmpty || detail.minCohortYear != null) ...[
                        _buildEligibilityTermsCard(detail),
                        const SizedBox(height: 20),
                      ],

                      // Info Pembayaran Panitia (Jika Berbayar)
                      if (event.isPaid && event.bankName != null) ...[
                        _buildBankPaymentCard(event),
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
              ctaResult: ctaResult,
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

  Widget _buildBankPaymentCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.cobalt, size: 16),
              const SizedBox(width: 6),
              Text(
                'Informasi Rekening Pembayaran',
                style: AppTypography.titleSmall.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${event.bankName}: ${event.bankAccountNumber}',
            style: AppTypography.numericCode.copyWith(fontSize: 14, color: AppColors.cobalt),
          ),
          if (event.bankAccountName != null) ...[
            const SizedBox(height: 2),
            Text(
              'a.n. ${event.bankAccountName}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
          ],
        ],
      ),
    );
  }

  /// STICKY BOTTOM ACTION BAR DENGAN 11 STATUS CTA SESUAI PRD §7.4.1
  Widget _buildBottomActionBar({
    required BuildContext context,
    required EventModel event,
    required CtaStateModel ctaResult,
  }) {
    Widget actionWidget;

    switch (ctaResult.status) {
      // 1. Event dibatalkan
      case EventCtaState.eventCancelled:
        actionWidget = Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.danger),
          ),
          child: Column(
            children: [
              Text(
                'Acara Ini Telah Dibatalkan',
                style: AppTypography.titleSmall.copyWith(color: AppColors.dangerText),
              ),
              if (ctaResult.reason != null) ...[
                const SizedBox(height: 2),
                Text(
                  ctaResult.reason!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
        break;

      // 2. Event sudah berakhir
      case EventCtaState.eventEnded:
        actionWidget = StickerButton(
          label: 'Pendaftaran Ditutup (Acara Selesai)',
          variant: StickerButtonVariant.outline,
          onPressed: null,
        );
        break;

      // 3. Belum login
      case EventCtaState.notLoggedIn:
        actionWidget = StickerButton(
          label: 'Masuk untuk Mendaftar',
          variant: StickerButtonVariant.primary,
          onPressed: () {
            AppHaptics.selection();
            _showGuestLoginSheet(context, event);
          },
        );
        break;

      // 4. Email belum terverifikasi
      case EventCtaState.emailUnverified:
        actionWidget = StickerButton(
          label: 'Verifikasi Email Terlebih Dahulu',
          variant: StickerButtonVariant.secondary,
          onPressed: () {
            AppHaptics.selection();
            context.push(AppRoutes.verifyEmail);
          },
        );
        break;

      // 5. Profil belum lengkap
      case EventCtaState.profileIncomplete:
        actionWidget = StickerButton(
          label: 'Lengkapi Profil (No. WhatsApp)',
          variant: StickerButtonVariant.secondary,
          onPressed: () {
            AppHaptics.selection();
            context.push(AppRoutes.profile);
          },
        );
        break;

      // 6. Sudah punya tiket aktif
      case EventCtaState.alreadyRegistered:
        actionWidget = StickerButton(
          label: 'Lihat Tiket Saya',
          variant: StickerButtonVariant.primary,
          icon: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 18),
          onPressed: () {
            AppHaptics.selection();
            context.go(AppRoutes.myTickets);
          },
        );
        break;

      // 7. Tidak eligible (Syarat Tidak Cocok)
      case EventCtaState.notEligible:
        final reason = ctaResult.reason ?? 'Acara ini tidak terbuka untuk prodi atau angkatan Anda.';
        actionWidget = Column(
          children: [
            Text(
              reason,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
            ),
            const SizedBox(height: 8),
            StickerButton(
              label: 'Syarat Tidak Cocok',
              variant: StickerButtonVariant.outline,
              onPressed: null,
            ),
          ],
        );
        break;

      // 8. Pendaftaran belum dibuka
      case EventCtaState.notOpenYet:
        actionWidget = StickerButton(
          label: event.registrationOpenAt != null
              ? 'Dibuka pada ${AppFormatters.eventDate(event.registrationOpenAt!)}'
              : 'Pendaftaran Belum Dibuka',
          variant: StickerButtonVariant.outline,
          onPressed: null,
        );
        break;

      // 9. Pendaftaran ditutup
      case EventCtaState.registrationClosed:
        actionWidget = StickerButton(
          label: 'Pendaftaran Ditutup',
          variant: StickerButtonVariant.outline,
          onPressed: null,
        );
        break;

      // 10. Kuota penuh
      case EventCtaState.quotaFull:
        actionWidget = StickerButton(
          label: 'Kuota Penuh',
          variant: StickerButtonVariant.danger,
          onPressed: null,
        );
        break;

      // 11. Eligible & Kuota Tersedia
      case EventCtaState.canRegister:
        actionWidget = StickerButton(
          label: event.isFree ? 'Daftar Sekarang (Gratis)' : 'Daftar & Bayar (${event.formattedPrice})',
          variant: StickerButtonVariant.primary,
          onPressed: () {
            AppHaptics.selection();
            context.push(AppRoutes.eventRegisterPath(event.slug));
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
            color: AppColors.ink.withValues(alpha: 0.08),
            offset: const Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(child: actionWidget),
    );
  }
}
