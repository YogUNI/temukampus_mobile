import 'dart:async';
import 'dart:math' as math;

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
import '../../data/models/event_model.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/empty_events_view.dart';
import '../widgets/event_filter_sheet.dart';
import '../widgets/event_grid_card.dart';
import '../widgets/event_grid_metrics.dart';
import '../widgets/event_grid_skeleton.dart';
import '../widgets/event_shimmer_loading.dart';
import '../widgets/event_ticket_card.dart';
import '../widgets/filter_chip_bar.dart';

/// Jelajah Acara Kampus: pencarian, kategori, toggle Grid ⇄ List, filter lanjut.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    // Auto-debounce 300ms sesuai PRD
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(eventsCatalogControllerProvider.notifier).setSearchQuery(query);
    });
  }

  void _openFilterBottomSheet(EventsCatalogState state) {
    AppHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EventFilterSheet(
          initialFormat: state.selectedFormat,
          initialOnlyFree: state.onlyFree,
          initialOnlySkp: state.onlySkp,
          initialSuitableForMe: state.suitableForMe,
          initialMaxPrice: state.maxPrice,
          initialOrganizationSlugs: state.organizationSlugs.toSet(),
          availableOrganizations: _availableOrganizations(state.events),
          maxPriceLimit: _priceSliderLimit(state.events),
          onApply: ({
            required format,
            required onlyFree,
            required onlySkp,
            required suitableForMe,
            required maxPrice,
            required organizationSlugs,
          }) {
            ref
                .read(eventsCatalogControllerProvider.notifier)
                .applyAdvancedFilters(
                  format: format,
                  onlyFree: onlyFree,
                  onlySkp: onlySkp,
                  suitableForMe: suitableForMe,
                  maxPrice: maxPrice,
                  organizationSlugs: organizationSlugs.toList(),
                );
          },
          onReset: () {
            ref.read(eventsCatalogControllerProvider.notifier).resetFilters();
          },
        );
      },
    );
  }

  /// Ormawa unik dari katalog saat ini, diurutkan berdasarkan nama.
  List<EventOrganizationModel> _availableOrganizations(List<EventModel> events) {
    final bySlug = <String, EventOrganizationModel>{};
    for (final event in events) {
      bySlug.putIfAbsent(event.organization.slug, () => event.organization);
    }
    final list = bySlug.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Batas atas slider harga: harga termahal dibulatkan ke kelipatan Rp 100rb.
  int _priceSliderLimit(List<EventModel> events) {
    var maxPrice = 0;
    for (final event in events) {
      maxPrice = math.max(maxPrice, event.price);
    }
    if (maxPrice <= 0) return 500000;
    const step = 100000;
    return ((maxPrice + step - 1) ~/ step) * step;
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(eventsCatalogControllerProvider);

    final categoryNames = [
      'Semua Kategori',
      ...catalogState.categories.where((c) => c.slug != 'all').map((c) => c.name),
    ];
    final categorySlugs = [
      'all',
      ...catalogState.categories.where((c) => c.slug != 'all').map((c) => c.slug),
    ];
    final selectedCategoryIndex = categorySlugs
        .indexOf(catalogState.selectedCategory)
        .clamp(0, categorySlugs.length - 1);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Jelajah Acara Kampus', style: AppTypography.titleMedium),
        elevation: 0,
        actions: [
          // Toggle Grid ⇄ List
          IconButton(
            tooltip: catalogState.viewMode == CatalogViewMode.grid
                ? 'Tampilan daftar'
                : 'Tampilan grid',
            icon: AnimatedSwitcher(
              duration: AppDurations.base,
              child: Icon(
                catalogState.viewMode == CatalogViewMode.grid
                    ? Icons.grid_view_rounded
                    : Icons.view_agenda_outlined,
                key: ValueKey(catalogState.viewMode),
                color: AppColors.ink,
              ),
            ),
            onPressed: () {
              AppHaptics.selection();
              ref.read(eventsCatalogControllerProvider.notifier).toggleViewMode();
            },
          ),
          // Tombol Filter dengan indikator titik sinyal
          Stack(
            children: [
              IconButton(
                tooltip: 'Filter lanjutan',
                icon: const Icon(Icons.tune_rounded, color: AppColors.ink),
                onPressed: () => _openFilterBottomSheet(catalogState),
              ),
              if (catalogState.hasActiveFilter)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.signal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // 1. Pill Search Bar (konsisten dengan Beranda)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.sm,
            ),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.borderPill,
                border: Border.all(color: AppColors.ink100),
                boxShadow: AppShadows.softCard,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Cari judul, topik, atau ormawa...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink400,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.cobalt,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            AppHaptics.light();
                            _searchController.clear();
                            ref
                                .read(eventsCatalogControllerProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),

          // 2. Kategori Horizontal Selector
          if (categoryNames.isNotEmpty) ...[
            FilterChipBar(
              items: categoryNames,
              activeIndexes: {selectedCategoryIndex},
              onSelected: (index) {
                ref
                    .read(eventsCatalogControllerProvider.notifier)
                    .setCategory(categorySlugs[index]);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 3. Ringkasan filter & jumlah acara
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${catalogState.events.length} Acara Ditemukan',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (catalogState.hasActiveFilter)
                  GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      _searchController.clear();
                      ref
                          .read(eventsCatalogControllerProvider.notifier)
                          .resetFilters();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Reset Filter',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.cobalt,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 4. Konten: Grid / List / Shimmer / Empty / Error
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobalt,
              onRefresh: () =>
                  ref.read(eventsCatalogControllerProvider.notifier).fetchEvents(),
              child: AnimatedSwitcher(
                duration: AppDurations.slow,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(catalogState.viewMode),
                  child: _buildBodyContent(catalogState),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(EventsCatalogState state) {
    final isGrid = state.viewMode == CatalogViewMode.grid;

    if (state.isLoading && state.events.isEmpty) {
      return isGrid
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: EventGridSkeleton(itemCount: 4),
            )
          : const EventShimmerLoading(itemCount: 4);
    }

    if (state.errorMessage != null && state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cobalt,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  AppHaptics.selection();
                  ref.read(eventsCatalogControllerProvider.notifier).fetchEvents();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.events.isEmpty) {
      return EmptyEventsView(
        onResetFilter: () {
          _searchController.clear();
          ref.read(eventsCatalogControllerProvider.notifier).resetFilters();
        },
      );
    }

    if (isGrid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            key: const PageStorageKey('explore_grid'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            itemCount: state.events.length,
            gridDelegate: EventGridMetrics.delegate(
              constraints.maxWidth - AppSpacing.gutter * 2,
            ),
            itemBuilder: (context, index) {
              final event = state.events[index];
              return EventGridCard(
                event: event,
                onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      key: const PageStorageKey('explore_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        final event = state.events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: EventTicketCard(
            event: event,
            onTap: () {
              AppHaptics.light();
              context.push(AppRoutes.eventDetailPath(event.slug));
            },
          ),
        );
      },
    );
  }
}