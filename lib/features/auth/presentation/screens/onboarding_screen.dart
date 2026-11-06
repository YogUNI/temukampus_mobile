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
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/utils/haptics.dart';
import '../widgets/onboarding_illustration.dart';

class OnboardingItem {
  final String badge;
  final String title;
  final String description;

  const OnboardingItem({
    required this.badge,
    required this.title,
    required this.description,
  });
}

/// Onboarding 3 langkah dengan parallax antar-slide.
///
/// Setiap slide bergerak lebih lambat dari halaman (translate 48pt + scale 0.94)
/// sehingga terasa seperti lapisan yang berkedalaman, bukan teks yang berganti.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const List<OnboardingItem> items = [
    OnboardingItem(
      badge: 'TERPUSAT & RESMI',
      title: 'Temukan Seluruh Acara Kampus UMB',
      description:
          'Seminar nasional, workshop teknologi, kompetisi, dan pameran ormawa kini terpusat dalam satu genggaman tanganmu.',
    ),
    OnboardingItem(
      badge: 'BEBAS REPOT',
      title: 'Daftar Cepat dengan Data Otomatis',
      description:
          'Cukup masukkan NIM sekali. Nama, prodi, dan fakultas langsung terhubung secara otomatis tanpa perlu mengisi formulir berulang kali.',
    ),
    OnboardingItem(
      badge: 'TIKET DIGITAL',
      title: 'Tiket QR Code Anti Ribet Hari-H',
      description:
          'Simpan tiket digitalmu secara offline. Tunjukkan QR code di meja registrasi kampus dan presensi tercatat dalam hitungan detik.',
    ),
  ];

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _entrance;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  Future<void> _completeToLogin() async {
    final cache = ref.read(localCacheServiceProvider);
    await cache.setHasSeenOnboarding(true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  Future<void> _exploreAsGuest() async {
    final cache = ref.read(localCacheServiceProvider);
    await cache.setHasSeenOnboarding(true);
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _goToPage(int index) {
    AppHaptics.light();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == OnboardingScreen.items.length - 1;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Aksen latar lembut di dua sudut
          Positioned(
            top: -120,
            right: -100,
            child: _Blob(size: 300, color: AppColors.cobalt.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Blob(size: 320, color: AppColors.signal.withValues(alpha: 0.07)),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header: brand mini + lewati
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entrance,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.sm,
                      0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.cobalt,
                            borderRadius: AppRadii.borderXs,
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'TemuKampus',
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            AppHaptics.light();
                            _exploreAsGuest();
                          },
                          child: Text(
                            'Lewati',
                            style: AppTypography.label.copyWith(
                              color: AppColors.ink500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Slide
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: OnboardingScreen.items.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double page = _currentIndex.toDouble();
                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions) {
                            page = _pageController.page ?? page;
                          }
                          final delta = (page - index).clamp(-1.0, 1.0);
                          return Opacity(
                            opacity: (1 - delta.abs() * 0.85).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(delta * 48, 0),
                              child: Transform.scale(
                                scale: 1 - delta.abs() * 0.06,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _SlideContent(
                          item: OnboardingScreen.items[index],
                          index: index,
                          entrance: _entrance,
                        ),
                      );
                    },
                  ),
                ),

                // Indikator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < OnboardingScreen.items.length; i++)
                      GestureDetector(
                        onTap: () => _goToPage(i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.sm,
                          ),
                          child: AnimatedContainer(
                            duration: AppDurations.base,
                            curve: Curves.easeOutCubic,
                            width: i == _currentIndex ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentIndex
                                  ? AppColors.cobalt
                                  : AppColors.ink200,
                              borderRadius: AppRadii.borderPill,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Aksi bawah
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _entrance,
                    curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entrance,
                      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        AppSpacing.xl,
                      ),
                      child: AnimatedSwitcher(
                        duration: AppDurations.base,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isLast
                            ? _LastPageActions(
                                key: const ValueKey('last'),
                                onLogin: _completeToLogin,
                                onGuest: _exploreAsGuest,
                              )
                            : SizedBox(
                                key: const ValueKey('next'),
                                width: double.infinity,
                                child: StickerButton(
                                  label: 'Lanjutkan',
                                  variant: StickerButtonVariant.primary,
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => _goToPage(_currentIndex + 1),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final OnboardingItem item;
  final int index;
  final Animation<double> entrance;

  const _SlideContent({
    required this.item,
    required this.index,
    required this.entrance,
  });

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(fade),
                child: OnboardingIllustration(index: index),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.cobaltLight,
                borderRadius: AppRadii.borderPill,
              ),
              child: Text(
                item.badge,
                style: AppTypography.micro.copyWith(
                  color: AppColors.cobalt,
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: AppTypography.hero.copyWith(fontSize: 25, height: 1.2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.ink500,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _LastPageActions extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onGuest;

  const _LastPageActions({
    super.key,
    required this.onLogin,
    required this.onGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: StickerButton(
            label: 'Masuk dengan Akun UMB',
            variant: StickerButtonVariant.primary,
            onPressed: onLogin,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: StickerButton(
            label: 'Jelajahi Acara Dulu',
            variant: StickerButtonVariant.outline,
            onPressed: onGuest,
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}