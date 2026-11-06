import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Gratis', 'Seminar', 'Ber-SKP', 'Workshop', 'Cocok untuk Saya'];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Greeting
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
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar dengan Ticket Notch Accent
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
                    hintText: 'Cari seminar, workshop, kompetisi...',
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

              // Filter Chips Cepat (Horizontal Scroll)
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
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

              // Section Hero / Event Unggulan Pekan Ini
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

              // Kartu Acara Unggulan Motif Tiket
              _buildFeaturedEventTicket(),
              const SizedBox(height: 28),

              // Section Segera Berlangsung
              Text('Segera Berlangsung di Kampus', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _buildSimpleEventCard(
                title: 'Workshop Flutter & AI Agents untuk Mahasiswa',
                org: 'UKM Computer Club UMB',
                date: 'Senin, 23 Nov 2026',
                format: 'Hybrid • Meruya & Zoom',
                price: 'Gratis',
                skp: '1 SKP',
              ),
              const SizedBox(height: 12),
              _buildSimpleEventCard(
                title: 'Lomba UI/UX Design Competition 2026',
                org: 'BEM Fasilkom UMB',
                date: 'Kamis, 26 Nov 2026',
                format: 'Daring (Online)',
                price: 'Rp 15.000',
                skp: '3 SKP',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedEventTicket() {
    return TicketContainer(
      punchRadius: 12.0,
      punchPositionPercent: 0.70,
      borderRadius: 16.0,
      borderColor: AppColors.ink,
      borderWidth: 1.5,
      hasShadow: true,
      shadowOffset: const Offset(3, 3),
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
                        color: AppColors.cobaltLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HIMA Teknik Informatika UMB',
                        style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10),
                      ),
                    ),
                    const StatusPill(
                      status: RegistrationStatusType.confirmed,
                      isStamp: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia',
                  style: AppTypography.titleMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.ink500),
                    const SizedBox(width: 6),
                    Text(
                      AppFormatters.eventDate(DateTime(2026, 11, 20)),
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.ink500),
                    const SizedBox(width: 4),
                    Text('Tower Meruya', style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildChip('SKP 2 Poin', AppColors.cobalt, AppColors.cobaltLight),
                    _buildChip('Sertifikat', AppColors.mintText, AppColors.mintLight),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: DottedTearLine(color: AppColors.ink200),
          ),
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HARGA TIKET', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.ink400)),
                    Text(
                      AppFormatters.rupiah(25000),
                      style: AppTypography.numericCode.copyWith(fontSize: 16, color: AppColors.cobalt),
                    ),
                  ],
                ),
                StickerButton(
                  label: 'Daftar',
                  variant: StickerButtonVariant.primary,
                  fullWidth: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Modul pendaftaran event segera dibuka di Tahap 3!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleEventCard({
    required String title,
    required String org,
    required String date,
    required String format,
    required String price,
    required String skp,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink200, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(org, style: AppTypography.badge.copyWith(color: AppColors.ink500, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cobaltLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(skp, style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_rounded, size: 13, color: AppColors.ink400),
                  const SizedBox(width: 4),
                  Text(date, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
              Text(
                price,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 13,
                  color: price == 'Gratis' ? AppColors.mintText : AppColors.cobalt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: AppTypography.badge.copyWith(color: textCol, fontSize: 10)),
    );
  }
}

