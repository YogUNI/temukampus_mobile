import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/event_ticket_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Semua',
    'Gratis',
    'Seminar',
    'Ber-SKP',
    'Workshop',
    'Cocok untuk Saya',
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final catalogState = ref.watch(eventsCatalogControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cobalt,
          onRefresh: () => ref.read(eventsCatalogControllerProvider.notifier).fetchEvents(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar Greeting & Profile Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Halo, ${user?.name.split(' ').first ?? 'Mahasiswa'}!',
                              style: AppTypography.hero.copyWith(fontSize: 22),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.signal,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cobaltLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            user?.academicSummary ?? "Teknik Informatika '24",
                            style: AppTypography.badge.copyWith(color: AppColors.cobalt),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.ink200),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 20),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Belum ada notifikasi baru.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Search Bar Ticket Motif
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink200, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () => context.go(AppRoutes.explore),
                    decoration: InputDecoration(
                      hintText: 'Cari seminar, workshop, lomba...',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.ink400),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cobalt),
                      suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.ink500),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Filter Chips Cepat (Horizontal Scroll)
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedFilterIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilterIndex = index);
                          ref
                              .read(eventsCatalogControllerProvider.notifier)
                              .setQuickFilterTag(_filters[index]);
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
                            _filters[index],
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
                const SizedBox(height: 28),

                // 4. Content Area (Loading Shimmer / Error / Empty / Success)
                if (catalogState.isLoading && catalogState.events.isEmpty) ...[
                  _buildLoadingShimmer(),
                ] else if (catalogState.errorMessage != null && catalogState.events.isEmpty) ...[
                  _buildErrorState(catalogState.errorMessage!),
                ] else if (catalogState.isEmpty) ...[
                  _buildEmptyState(),
                ] else ...[
                  // Hero Unggulan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Acara Unggulan Pekan Ini', style: AppTypography.titleMedium),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.explore),
                        child: Text(
                          'Lihat Semua',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (catalogState.events.isNotEmpty)
                    EventTicketCard(
                      event: catalogState.events.first,
                      onTap: () => context.push(AppRoutes.eventDetailPath(catalogState.events.first.slug)),
                    ),
                  const SizedBox(height: 32),

                  // Section Cocok Untuk Jurusanmu
                  if (user?.isUmbStudent ?? true) ...[
                    Row(
                      children: [
                        Text('Cocok Untuk Jurusanmu', style: AppTypography.titleMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.signalLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRODI PILIHAN',
                            style: AppTypography.badge.copyWith(color: AppColors.ink, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...catalogState.events
                        .skip(1)
                        .take(2)
                        .map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: EventTicketCard(
                                event: event,
                                onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
                              ),
                            )),
                    const SizedBox(height: 16),
                  ],

                  // Section Segera Berlangsung
                  Text('Segera Berlangsung', style: AppTypography.titleMedium),
                  const SizedBox(height: 14),
                  ...catalogState.events
                      .skip(3)
                      .map((event) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: EventTicketCard(
                              event: event,
                              onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
                            ),
                          )),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(3, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: AppColors.ink100,
            highlightColor: Colors.white,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
              ),
              onPressed: () => ref.read(eventsCatalogControllerProvider.notifier).fetchEvents(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.ink400),
            const SizedBox(height: 12),
            Text('Belum ada acara yang sesuai dengan filter ini.', style: AppTypography.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Coba ubah kata kunci atau pilih filter lainnya.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
