import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/empty_events_view.dart';
import '../widgets/event_grid_card.dart';
import '../widgets/event_grid_metrics.dart';
import '../widgets/event_grid_skeleton.dart';
import '../widgets/featured_event_carousel.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/home_quick_filters.dart';

/// Beranda TemuKampus.
///
/// Struktur: header personal → pencarian → carousel unggulan → chip cepat →
/// grid 2-kolom. Tidak ada state filter lokal di sini: seluruh keadaan filter
/// adalah turunan dari [eventsCatalogControllerProvider].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Jumlah acara yang ikut carousel unggulan.
  static const int featuredCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final catalogState = ref.watch(eventsCatalogControllerProvider);
    final user = authState.user;
    final controller = ref.read(eventsCatalogControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cobalt,
          onRefresh: () => controller.fetchEvents(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  user: user,
                  onNotificationTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Belum ada notifikasi baru.')),
                    );
                  },
                ),
                if (user == null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _GuestBanner(
                    onLogin: () {
                      AppHaptics.selection();
                      context.push(AppRoutes.login);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _SearchPill(
                  onTap: () {
                    AppHaptics.light();
                    context.go(AppRoutes.explore);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Carousel acara unggulan
                if (catalogState.isLoading && catalogState.events.isEmpty)
                  const FeaturedEventSkeleton()
                else if (catalogState.events.isNotEmpty)
                  FeaturedEventCarousel(
                    events: catalogState.events
                        .take(HomeScreen.featuredCount)
                        .toList(growable: false),
                    onEventTap: (event) =>
                        context.push(AppRoutes.eventDetailPath(event.slug)),
                  ),
                const SizedBox(height: AppSpacing.xxl),

                // Chip filter cepat — status aktif diturunkan dari state katalog
                FilterChipBar(
                  items: HomeQuickFilters.labels,
                  activeIndexes: HomeQuickFilters.activeIndexes(catalogState),
                  padding: EdgeInsets.zero,
                  onSelected: (index) =>
                      controller.setQuickFilterTag(HomeQuickFilters.labels[index]),
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildContent(context, ref, catalogState, user: user),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    EventsCatalogState state, {
    required UserModel? user,
  }) {
    if (state.isLoading && state.events.isEmpty) {
      return const EventGridSkeleton(itemCount: 4);
    }

    if (state.errorMessage != null && state.events.isEmpty) {
      return _ErrorState(
        message: state.errorMessage!,
        onRetry: () {
          AppHaptics.selection();
          ref.read(eventsCatalogControllerProvider.notifier).fetchEvents();
        },
      );
    }

    if (state.events.isEmpty) {
      return EmptyEventsView(
        onResetFilter: () =>
            ref.read(eventsCatalogControllerProvider.notifier).resetFilters(),
      );
    }

    final isUmbStudent = user?.isUmbStudent == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      isUmbStudent ? 'Khusus Jurusanmu' : 'Rekomendasi Acara',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.signalLight,
                      borderRadius: AppRadii.borderXs,
                    ),
                    child: Text(
                      isUmbStudent ? 'PILIHAN PRODI' : 'POPULER',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.ink,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                AppHaptics.light();
                context.go(AppRoutes.explore);
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.cobalt,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.cobalt,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: state.events.length,
              gridDelegate: EventGridMetrics.delegate(constraints.maxWidth),
              itemBuilder: (context, index) {
                final event = state.events[index];
                return EventGridCard(
                  event: event,
                  onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderPill,
          border: Border.all(color: AppColors.ink100),
          boxShadow: AppShadows.softCard,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.cobalt, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Cari seminar, workshop, ormawa...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink400,
                  fontSize: 13.5,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink100),
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.ink, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final VoidCallback onLogin;

  const _GuestBanner({required this.onLogin});

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
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.cobalt,
              borderRadius: AppRadii.borderXs,
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Tamu Aktif',
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 13,
                    color: AppColors.cobalt,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Masuk untuk daftar acara & simpan tiketmu.',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.ink700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StickerButton(
            label: 'Masuk',
            fullWidth: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            variant: StickerButtonVariant.primary,
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
