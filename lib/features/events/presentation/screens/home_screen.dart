import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/empty_events_view.dart';
import '../widgets/event_shimmer_loading.dart';
import '../widgets/event_ticket_card.dart';
import '../widgets/filter_chip_bar.dart';

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
                              user != null ? 'Halo, ${user.name.split(' ').first}!' : 'Halo, Kawan Kampus!',
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
                            user?.academicSummary ?? 'Mode Tamu (Eksplorasi)',
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
                        AppHaptics.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Belum ada notifikasi baru.')),
                        );
                      },
                    ),
                  ],
                ),

                // Banner Ajakan Masuk Jika Mode Tamu
                if (user == null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cobalt, width: 1.4),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(2.5, 2.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cobalt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Tamu Aktif',
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 13,
                                  color: AppColors.cobalt,
                                ),
                              ),
                              const SizedBox(height: 1),
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
                        const SizedBox(width: 8),
                        StickerButton(
                          label: 'Masuk',
                          fullWidth: false,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          variant: StickerButtonVariant.primary,
                          onPressed: () {
                            AppHaptics.selection();
                            context.push(AppRoutes.login);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 2. Search Bar Ticket Motif
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink, width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      AppHaptics.light();
                      context.go(AppRoutes.explore);
                    },
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

                // 3. Hero Carousel Banner Berbayang (3, 3) Motif Tiket Kampus
                if (catalogState.events.isNotEmpty) ...[
                  _buildHeroBanner(catalogState.events.first),
                  const SizedBox(height: 24),
                ],

                // 4. Filter Chips Cepat (FilterChipBar)
                FilterChipBar(
                  items: _filters,
                  selectedIndex: _selectedFilterIndex,
                  padding: EdgeInsets.zero,
                  onSelected: (index) {
                    setState(() => _selectedFilterIndex = index);
                    ref
                        .read(eventsCatalogControllerProvider.notifier)
                        .setQuickFilterTag(_filters[index]);
                  },
                ),
                const SizedBox(height: 24),

                // 5. Content Area (Loading Shimmer / Error / Empty / Success)
                if (catalogState.isLoading && catalogState.events.isEmpty) ...[
                  const EventShimmerLoading(itemCount: 3),
                ] else if (catalogState.errorMessage != null && catalogState.events.isEmpty) ...[
                  _buildErrorState(catalogState.errorMessage!),
                ] else if (catalogState.isEmpty) ...[
                  EmptyEventsView(
                    onResetFilter: () {
                      setState(() => _selectedFilterIndex = 0);
                      ref.read(eventsCatalogControllerProvider.notifier).resetFilters();
                    },
                  ),
                ] else ...[
                  // Section Rekomendasi Khusus / Populer
                  Row(
                    children: [
                      Text(
                        user?.isUmbStudent == true ? 'Khusus Untuk Jurusanmu' : 'Rekomendasi Acara Kampus',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.signalLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user?.isUmbStudent == true ? 'PRODI PILIHAN' : 'POPULER DI KAMPUS',
                          style: AppTypography.badge.copyWith(color: AppColors.ink, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...catalogState.events
                      .take(2)
                      .map((event) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: EventTicketCard(
                              event: event,
                              onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
                            ),
                          )),
                  const SizedBox(height: 16),

                  // Section Segera Berlangsung
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Segera Berlangsung', style: AppTypography.titleMedium),
                      GestureDetector(
                        onTap: () {
                          AppHaptics.light();
                          context.go(AppRoutes.explore);
                        },
                        child: Text(
                          'Lihat Semua',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...catalogState.events
                      .skip(2)
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

  Widget _buildHeroBanner(dynamic event) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        context.push(AppRoutes.eventDetailPath(event.slug));
      },
      child: TicketContainer(
        punchRadius: 14.0,
        punchPositionPercent: 0.65,
        borderRadius: 16.0,
        borderColor: AppColors.ink,
        borderWidth: 1.6,
        hasShadow: true,
        shadowOffset: const Offset(3, 3),
        color: AppColors.cobalt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.signal,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.ink, width: 1.2),
                        ),
                        child: Text(
                          'UNGGULAN PEKAN INI',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        event.formatLabel.toUpperCase(),
                        style: AppTypography.badge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: AppTypography.hero.copyWith(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        AppFormatters.eventDate(event.startAt),
                        style: AppTypography.bodySmall.copyWith(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DottedTearLine(color: Colors.white38),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: Colors.black.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.isFree ? 'TIKET GRATIS' : 'TIKET: ${event.formattedPrice}',
                    style: AppTypography.numericCode.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Ambil Tiket',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}
