import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/glass_icon_button.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../data/models/event_model.dart';
import '../controllers/event_detail_controller.dart';
import '../widgets/event_cta_bar.dart';
import '../widgets/event_ticket_info_card.dart';
import '../widgets/quota_progress_bar.dart';

class EventDetailScreen extends ConsumerWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(eventDetailControllerProvider(slug));
    final authState = ref.watch(authNotifierProvider);

    if (detailState.isLoading) {
      return const _DetailSkeleton();
    }

    if (detailState.errorMessage != null || detailState.detail == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: AppSpacing.md),
                Text(
                  detailState.errorMessage ?? 'Acara tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
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

    // Kalkulator 11-state ketat (PRD §7.4.1)
    final ctaResult = EventCtaCalculator.calculate(
      event: event,
      user: authState.user,
      hasActiveTicket: detail.hasUserRegistered,
      activeTicketCode: detail.userTicketCode,
    );
    final ctaView = EventCtaView.resolve(ctaResult, event);
    final ctaAction = _ctaAction(context, ctaResult, event);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildPosterHeader(context, event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xl,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (authState.user == null) ...[
                        _GuestNotice(
                          eventTitle: event.title,
                          onLogin: () => _showGuestLoginSheet(context, event),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _OrganizerRow(event: event),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        event.title,
                        style: AppTypography.hero.copyWith(fontSize: 23, height: 1.22),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _BadgeRow(event: event),
                      const SizedBox(height: AppSpacing.xl),

                      // Kartu jadwal bergaya tiket (notch + perforasi)
                      EventTicketInfoCard(event: event),
                      const SizedBox(height: AppSpacing.lg),

                      // Sisa kuota
                      _SoftCard(
                        child: QuotaProgressBar(
                          quota: event.quota,
                          remainingQuota: event.remainingQuota,
                          registeredCount: event.registeredCount,
                          isFull: event.isFull,
                        ),
                      ),

                      if (detail.allowedStudyPrograms.isNotEmpty ||
                          detail.minCohortYear != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _EligibilityCard(detail: detail),
                      ],

                      if (event.isPaid && event.bankName != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _BankPaymentCard(event: event),
                      ],

                      const SizedBox(height: AppSpacing.xxl),
                      Text('Tentang Kegiatan', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        detail.description,
                        style: AppTypography.bodyMedium.copyWith(
                          height: 1.6,
                          color: AppColors.ink,
                        ),
                      ),

                      if (detail.terms != null && detail.terms!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        Text('Tata Tertib & Ketentuan', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          detail.terms!,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.55,
                            color: AppColors.ink500,
                          ),
                        ),
                      ],

                      // Ruang agar konten terakhir tidak tertutup sticky bar
                      SizedBox(
                        height: EventCtaBar.contentHeight + AppSpacing.huge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky bottom bar: harga kiri + CTA lebar kanan (tinggi tetap)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: EventCtaBar(view: ctaView, onPressed: ctaAction),
          ),
        ],
      ),
    );
  }

  /// Aksi untuk tiap status CTA yang bisa dijalankan pengguna.
  VoidCallback? _ctaAction(
    BuildContext context,
    CtaStateModel cta,
    EventModel event,
  ) {
    switch (cta.status) {
      case EventCtaState.canRegister:
        return () {
          AppHaptics.selection();
          context.push(AppRoutes.eventRegisterPath(event.slug));
        };
      case EventCtaState.notLoggedIn:
        return () {
          AppHaptics.selection();
          _showGuestLoginSheet(context, event);
        };
      case EventCtaState.emailUnverified:
        return () {
          AppHaptics.selection();
          context.push(AppRoutes.verifyEmail);
        };
      case EventCtaState.profileIncomplete:
        return () {
          AppHaptics.selection();
          context.push(AppRoutes.profile);
        };
      case EventCtaState.alreadyRegistered:
        return () {
          AppHaptics.selection();
          context.go(AppRoutes.myTickets);
        };
      default:
        return null;
    }
  }

  Widget _buildPosterHeader(BuildContext context, EventModel event) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Center(
          child: GlassIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Kembali',
            onPressed: () {
              AppHaptics.light();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
      ),
      actions: [
        Center(
          child: GlassIconButton(
            icon: Icons.ios_share_rounded,
            semanticLabel: 'Bagikan acara',
            onPressed: () {
              AppHaptics.light();
              try {
                SharePlus.instance.share(
                  ShareParams(
                    text: 'Temukan acara "${event.title}" di TemuKampus Mobile '
                        '(Universitas Mercu Buana)!\nhttp://temukampus.test/events/${event.slug}',
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
        ),
        const SizedBox(width: AppSpacing.md),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkOrAssetImage(
              imagePath: event.posterUrl,
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.gutter,
              right: AppSpacing.gutter,
              bottom: AppSpacing.xl,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.signal,
                      borderRadius: AppRadii.borderXs,
                    ),
                    child: Text(
                      (event.category ?? 'Acara Kampus').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.micro.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (event.isFull) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: AppRadii.borderXs,
                      ),
                      child: Text(
                        'KUOTA PENUH',
                        style: AppTypography.micro.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestLoginSheet(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cobaltLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.login_rounded, color: AppColors.cobalt, size: 26),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Masuk untuk Mendaftar',
                  style: AppTypography.titleMedium.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Untuk mendaftar acara "${event.title}", silakan masuk dengan akun mahasiswa UMB atau buat akun baru.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink500,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: StickerButton(
                    label: 'Masuk Sekarang',
                    variant: StickerButtonVariant.primary,
                    onPressed: () {
                      Navigator.pop(ctx);
                      final encodedRedirect =
                          Uri.encodeComponent(AppRoutes.eventRegisterPath(event.slug));
                      context.push(
                        '${AppRoutes.login}?redirect=$encodedRedirect&reason=register',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
}

class _OrganizerRow extends StatelessWidget {
  final EventModel event;

  const _OrganizerRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.cobaltLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.25)),
          ),
          child: const Center(
            child: Icon(Icons.groups_rounded, color: AppColors.cobalt, size: 19),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Penyelenggara',
                style: AppTypography.micro.copyWith(
                  color: AppColors.ink400,
                  fontSize: 9.5,
                ),
              ),
              Text(
                event.organization.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 13.5,
                  color: AppColors.cobalt,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.ink100,
            borderRadius: AppRadii.borderXs,
          ),
          child: Text(
            event.formatLabel,
            style: AppTypography.micro.copyWith(
              color: AppColors.ink700,
              fontSize: 9.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final EventModel event;

  const _BadgeRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Badge(
          label: event.isFree ? 'Gratis' : event.formattedPrice,
          color: event.isFree ? AppColors.mintText : AppColors.cobalt,
          bgColor: event.isFree ? AppColors.mintLight : AppColors.cobaltLight,
        ),
        if (event.hasSkp)
          _Badge(
            label: '${event.skpPoints} Poin SKP',
            color: AppColors.cobalt,
            bgColor: AppColors.cobaltLight,
          ),
        if (event.hasCertificate)
          _Badge(
            label: 'E-Sertifikat',
            color: AppColors.mintText,
            bgColor: AppColors.mintLight,
          ),
        _Badge(
          label: event.audience == 'umb_only'
              ? 'Khusus Mahasiswa UMB'
              : (event.audience == 'restricted' ? 'Terbatas Jurusan' : 'Terbuka Umum'),
          color: AppColors.ink700,
          bgColor: AppColors.ink100,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.borderPill,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  final EventDetailModel detail;

  const _EligibilityCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cobaltLight,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.cobalt, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Syarat Kelayakan Peserta',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.cobalt,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
}

class _BankPaymentCard extends StatelessWidget {
  final EventModel event;

  const _BankPaymentCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.cobalt,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Informasi Rekening Pembayaran',
                style: AppTypography.titleSmall.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${event.bankName}: ${event.bankAccountNumber}',
            style: AppTypography.numericCode.copyWith(fontSize: 14, color: AppColors.cobalt),
          ),
          if (event.bankAccountName != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'a.n. ${event.bankAccountName}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink100),
        boxShadow: AppShadows.softCard,
      ),
      child: child,
    );
  }
}

class _GuestNotice extends StatelessWidget {
  final String eventTitle;
  final VoidCallback onLogin;

  const _GuestNotice({required this.eventTitle, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cobaltLight,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.cobalt, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Kamu sedang menjelajah sebagai tamu. Masuk untuk mendaftar acara ini.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink700,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onLogin,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Masuk',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.cobalt,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 300, color: AppColors.ink100),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final width in [0.35, 0.85, 1.0, 0.6])
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: FractionallySizedBox(
                        widthFactor: width,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.ink100,
                            borderRadius: AppRadii.borderXs,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    height: 161,
                    decoration: BoxDecoration(
                      color: AppColors.ink100,
                      borderRadius: AppRadii.borderMd,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
