import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../controllers/panitia_controller.dart';

/// Hub panel panitia di aplikasi: ringkasan organisasi + daftar acara yang
/// dikelola, dengan pintu masuk ke verifikasi pembayaran, daftar peserta, dan
/// scanner presensi.
///
/// Padanan `/panitia` (dashboard) di website.
class PanitiaHomeScreen extends ConsumerWidget {
  const PanitiaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(panitiaDashboardProvider);
    final events = ref.watch(panitiaEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Panel Panitia', style: AppTypography.titleMedium),
      ),
      body: RefreshIndicator(
        color: AppColors.cobalt,
        onRefresh: () async {
          ref.invalidate(panitiaDashboardProvider);
          ref.invalidate(panitiaEventsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            dashboard.when(
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                message: _clean(error),
                onRetry: () => ref.invalidate(panitiaDashboardProvider),
              ),
              data: (data) => _Summary(data: data),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan Presensi',
                    color: AppColors.cobalt,
                    onTap: () {
                      AppHaptics.selection();
                      context.push(AppRoutes.scannerSelectEvent);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.verified_rounded,
                    label: 'Verifikasi',
                    color: AppColors.signal,
                    onTap: () {
                      AppHaptics.selection();
                      final list = ref.read(panitiaEventsProvider).valueOrNull ?? [];

                      if (list.isEmpty) return;

                      context.push(AppRoutes.panitiaRegistrantsPath(list.first.id));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Acara yang kamu kelola',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            events.when(
              loading: () => const _LoadingCard(),
              error: (error, _) => _ErrorCard(
                message: _clean(error),
                onRetry: () => ref.invalidate(panitiaEventsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyCard(
                    text: 'Belum ada acara yang kamu kelola. '
                        'Hubungi admin bila organisasimu belum terdaftar.',
                  );
                }

                return Column(
                  children: [
                    for (final event in list) ...[
                      _EventTile(
                        title: event.title,
                        organization: event.organizationName,
                        registered: event.registeredCount,
                        attended: event.attendedCount,
                        onTap: () {
                          AppHaptics.selection();
                          context.push(AppRoutes.panitiaRegistrantsPath(event.id));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _clean(Object error) {
    final text = error.toString();

    return text.contains(':') ? text.split(':').skip(1).join(':').trim() : text;
  }
}

class _Summary extends StatelessWidget {
  final dynamic data;

  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('Menunggu', '${data.pendingVerification}', Icons.hourglass_top_rounded),
      ('Terkonfirmasi', '${data.confirmed}', Icons.verified_rounded),
      ('Hadir', '${data.attended}', Icons.how_to_reg_rounded),
      ('Acara', '${data.eventsTotal}', Icons.event_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cobalt, AppColors.cobaltDark],
        ),
        borderRadius: AppRadii.borderXl,
        boxShadow: AppShadows.liftedCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan organisasi',
            style: AppTypography.label.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final (label, value, icon) in items)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.16),
                          borderRadius: AppRadii.borderSm,
                        ),
                        child: Icon(icon, size: 17, color: AppColors.surface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.micro.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final String title;
  final String organization;
  final int registered;
  final int attended;
  final VoidCallback onTap;

  const _EventTile({
    required this.title,
    required this.organization,
    required this.registered,
    required this.attended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Kelola peserta $title',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderLg,
            border: Border.all(color: AppColors.ink200, width: 1.4),
            boxShadow: AppShadows.softCard,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cobaltLight,
                  borderRadius: AppRadii.borderSm,
                ),
                child: const Icon(Icons.event_available_rounded, color: AppColors.cobalt),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$registered pendaftar · $attended hadir',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.ink500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink400),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderLg,
          border: Border.all(color: AppColors.ink200, width: 1.4),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator(color: AppColors.cobalt)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: AppRadii.borderLg,
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.ink200, width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
      ),
    );
  }
}
