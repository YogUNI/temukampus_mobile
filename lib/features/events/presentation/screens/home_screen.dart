import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../data/models/event_model.dart';
import '../controllers/events_catalog_controller.dart';
import '../widgets/empty_events_view.dart';
import '../widgets/event_grid_card.dart';
import '../widgets/event_shimmer_loading.dart';
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
                // 1. Top Bar Personalized Header (Inspirasi: Doctor Booking App)
                Row(
                  children: [
                    // Avatar Pengguna / Mahasiswa
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cobalt, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x152447F5),
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user != null
                            ? const AppNetworkOrAssetImage(
                                imagePath: 'assets/images/avatars/user_avatar.jpg',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.cobaltLight,
                                child: const Icon(Icons.person_rounded, color: AppColors.cobalt, size: 26),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Sapaan & Status Mahasiswa
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user != null ? 'Halo, ${user.name.split(' ').first}! 👋' : 'Halo, Kawan Kampus! 👋',
                                  style: AppTypography.hero.copyWith(fontSize: 19),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.isUmbStudent == true
                                ? '${user?.studyProgram?.name ?? "Teknik Informatika"} \'${user?.cohortYear ?? 24}'
                                : 'Mode Tamu (Eksplorasi)',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.ink500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lonceng Notifikasi dengan Unread Dot
                    GestureDetector(
                      onTap: () {
                        AppHaptics.light();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Belum ada notifikasi baru.')),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink100, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A12162B),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 22),
                            Positioned(
                              top: 10,
                              right: 11,
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
                      ),
                    ),
                  ],
                ),

                // Banner Ajakan Masuk Jika Mode Tamu
                if (user == null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cobalt, width: 1.2),
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
                                  fontWeight: FontWeight.w700,
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

                // 2. Pill Search Bar (Inspirasi: Oakory Furniture & Doctor Booking)
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.ink100, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A12162B),
                        offset: Offset(0, 4),
                        blurRadius: 12,
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
                      hintText: 'Cari seminar, workshop, ormawa...',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.ink400, fontSize: 13.5),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 10),
                        child: Icon(Icons.search_rounded, color: AppColors.cobalt, size: 22),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 24),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.ink100),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.ink, size: 18),
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Hero Featured Event Banner dengan Poster Visual
                if (catalogState.events.isNotEmpty) ...[
                  _buildHeroBanner(catalogState.events.first),
                  const SizedBox(height: 24),
                ],

                // 4. Kategori Kapsul Modern (FilterChipBar)
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
                const SizedBox(height: 22),

                // 5. Content Area: Grid 2-Kolom Acara Kampus (Inspirasi: 9 Art Store)
                if (catalogState.isLoading && catalogState.events.isEmpty) ...[
                  const EventShimmerLoading(itemCount: 4),
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
                  // Header Section Acara
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            user?.isUmbStudent == true ? 'Khusus Jurusanmu' : 'Rekomendasi Acara',
                            style: AppTypography.titleMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.signalLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user?.isUmbStudent == true ? 'PILIHAN PRODI' : 'POPULER',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.ink,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          AppHaptics.light();
                          context.go(AppRoutes.explore);
                        },
                        child: Row(
                          children: [
                            Text(
                              'Lihat Semua',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.cobalt,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.cobalt),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // GRID 2-KOLOM ACARA KAMPUS (Modern Production Grid)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: catalogState.events.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final event = catalogState.events[index];
                      return EventGridCard(
                        event: event,
                        onTap: () => context.push(AppRoutes.eventDetailPath(event.slug)),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner Hero Unggulan dengan Poster Nyata dan Efek Modern
  Widget _buildHeroBanner(EventModel event) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        context.push(AppRoutes.eventDetailPath(event.slug));
      },
      child: Container(
        height: 205,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(3.5, 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gambar Poster Nyata sebagai Latar Belakang
            Positioned.fill(
              child: AppNetworkOrAssetImage(
                imagePath: event.posterUrl,
                fit: BoxFit.cover,
              ),
            ),

            // Lapisan Gradasi Gelap Elegan
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Konten Teks & Tombol Aksi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.signal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'UNGGULAN PEKAN INI',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.ink,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.format.toUpperCase(),
                          style: AppTypography.badge.copyWith(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: AppTypography.hero.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            AppFormatters.eventDate(event.startAt),
                            style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 11.5),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.formattedPrice,
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Acara',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.ink),
                          ],
                        ),
                      ),
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
