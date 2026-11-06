import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/event_filter_sheet.dart';
import '../widgets/event_ticket_card.dart';

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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(eventsCatalogControllerProvider.notifier).setSearchQuery(query);
    });
  }

  void _openFilterBottomSheet() {
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

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Katalog Acara Kampus', style: AppTypography.titleMedium),
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
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Cari judul, topik, atau ormawa...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cobalt),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(eventsCatalogControllerProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Kategori Horizontal Selector
          if (catalogState.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: catalogState.categories.length,
                itemBuilder: (context, index) {
                  final cat = catalogState.categories[index];
                  final isSelected = catalogState.selectedCategory == cat.slug;

                  return GestureDetector(
                    onTap: () {
                      ref.read(eventsCatalogControllerProvider.notifier).setCategory(cat.slug);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cobalt : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.cobalt : AppColors.ink200,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        cat.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.white : AppColors.ink700,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. List Acara / Shimmer / Empty State
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
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: AppColors.ink100,
            highlightColor: Colors.white,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    if (state.errorMessage != null && state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 14),
              Text(state.errorMessage!, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cobalt, foregroundColor: Colors.white),
                onPressed: () => ref.read(eventsCatalogControllerProvider.notifier).fetchEvents(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.ink100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.ink400),
              ),
              const SizedBox(height: 16),
              Text(
                'Acara tidak ditemukan',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Coba ubah kata kunci atau bersihkan filter yang aktif.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(eventsCatalogControllerProvider.notifier).resetFilters();
                },
                child: const Text('Reset Filter'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        final event = state.events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EventTicketCard(
            event: event,
            onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
          ),
        );
      },
    );
  }
}
