import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/empty_events_view.dart';
import '../widgets/event_filter_sheet.dart';
import '../widgets/event_shimmer_loading.dart';
import '../widgets/event_ticket_card.dart';
import '../widgets/filter_chip_bar.dart';

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

  void _openFilterBottomSheet() {
    AppHaptics.selection();
    final state = ref.read(eventsCatalogControllerProvider);

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
          onApply: ({
            required format,
            required onlyFree,
            required onlySkp,
            required suitableForMe,
          }) {
            ref.read(eventsCatalogControllerProvider.notifier).applyAdvancedFilters(
                  format: format,
                  onlyFree: onlyFree,
                  onlySkp: onlySkp,
                  suitableForMe: suitableForMe,
                );
          },
          onReset: () {
            ref.read(eventsCatalogControllerProvider.notifier).resetFilters();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(eventsCatalogControllerProvider);

    final categoryNames = ['Semua Kategori', ...catalogState.categories.where((c) => c.slug != 'all').map((c) => c.name)];
    final categorySlugs = ['all', ...catalogState.categories.where((c) => c.slug != 'all').map((c) => c.slug)];
    final selectedCategoryIndex = categorySlugs.indexOf(catalogState.selectedCategory).clamp(0, categorySlugs.length - 1);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Jelajah Acara Kampus', style: AppTypography.titleMedium),
        elevation: 0,
        actions: [
          // Tombol Filter dengan Indicator Titik Sinyal jika ada filter aktif
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.ink),
                onPressed: _openFilterBottomSheet,
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar dengan Sticker Border & 300ms Debounce
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Cari judul, topik, atau ormawa...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.ink400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cobalt),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            AppHaptics.light();
                            _searchController.clear();
                            ref.read(eventsCatalogControllerProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // 2. Kategori Horizontal Selector via FilterChipBar
          if (categoryNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilterChipBar(
              items: categoryNames,
              selectedIndex: selectedCategoryIndex >= 0 ? selectedCategoryIndex : 0,
              onSelected: (index) {
                final slug = categorySlugs[index];
                ref.read(eventsCatalogControllerProvider.notifier).setCategory(slug);
              },
            ),
            const SizedBox(height: 12),
          ],

          // 3. Status Ringkasan Filter & Jumlah Acara
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${catalogState.events.length} Acara Ditemukan',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.ink500),
                ),
                if (catalogState.hasActiveFilter)
                  GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      _searchController.clear();
                      ref.read(eventsCatalogControllerProvider.notifier).resetFilters();
                    },
                    child: Text(
                      'Reset Filter',
                      style: AppTypography.badge.copyWith(color: AppColors.cobalt),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 4. List Acara / Shimmer / Empty State
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobalt,
              onRefresh: () => ref.read(eventsCatalogControllerProvider.notifier).fetchEvents(),
              child: _buildBodyContent(catalogState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(EventsCatalogState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: EventShimmerLoading(itemCount: 4),
      );
    }

    if (state.errorMessage != null && state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        final event = state.events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
