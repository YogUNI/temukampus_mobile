import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/storage/local_cache_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      icon: Icons.explore_rounded,
      badge: 'TERPUSAT & RESMI',
      title: 'Temukan Seluruh Acara Kampus UMB',
      description:
          'Seminar nasional, workshop teknologi, kompetisi, dan pameran ormawa kini terpusat dalam satu genggaman tanganmu.',
    ),
    OnboardingItem(
      icon: Icons.bolt_rounded,
      badge: 'BEBAS REPOT',
      title: 'Daftar Cepat dengan Data Otomatis',
      description:
          'Cukup masukkan NIM sekali. Nama, prodi, dan fakultas langsung terhubung secara otomatis tanpa perlu mengisi formulir berulang kali.',
    ),
    OnboardingItem(
      icon: Icons.qr_code_2_rounded,
      badge: 'TIKET DIGITAL',
      title: 'Tiket QR Code Anti Ribet Hari-H',
      description:
          'Simpan tiket digitalmu secara offline. Tunjukkan QR code di meja registrasi kampus dan presensi tercatat dalam hitungan detik.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final cache = ref.read(localCacheServiceProvider);
    await cache.setHasSeenOnboarding(true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              'Lewati',
              style: AppTypography.label.copyWith(color: AppColors.ink500),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ilustrasi Icon Berkarakter Stiker Kampus
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.ink, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.ink,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 58,
                            color: AppColors.cobalt,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Badge Kategori
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cobaltLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            item.badge,
                            style: AppTypography.badge.copyWith(color: AppColors.cobalt),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Judul Slide
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.hero.copyWith(
                            fontSize: 24,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Deskripsi
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.ink500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (index) {
                final isActive = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.cobalt : AppColors.ink200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Tombol Navigasi Bawah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _currentIndex == _items.length - 1
                  ? StickerButton(
                      label: 'Mulai Sekarang',
                      variant: StickerButtonVariant.primary,
                      onPressed: _completeOnboarding,
                    )
                  : StickerButton(
                      label: 'Lanjutkan',
                      variant: StickerButtonVariant.primary,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String badge;
  final String title;
  final String description;

  const OnboardingItem({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });
}
