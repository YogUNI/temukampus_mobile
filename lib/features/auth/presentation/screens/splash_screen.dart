import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../controllers/auth_notifier.dart';
import '../controllers/auth_state.dart';

/// Splash screen TemuKampus.
///
/// Timeline (1200ms, sinkron dengan waktu navigasi):
/// - 0–42%  : logo tiket tumbuh (scale 0.72→1, easeOutBack) + settle rotasi
/// - 35–85% : kilau (shine) menyapu logo
/// - 18–55% : wordmark & subjudul naik + fade
/// - 5–95%  : progress bar terisi
///
/// Semua animasi berhingga (tidak ada `repeat`) supaya transisi ke layar
/// berikutnya tetap tenang dan tes widget bisa `pumpAndSettle`.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Durasi total animasi splash sebelum navigasi.
  static const Duration totalDuration = Duration(milliseconds: 1200);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markRotation;
  late final Animation<double> _shine;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _wordmarkOffset;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _progress;
  late final Animation<double> _ambient;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: SplashScreen.totalDuration,
    );

    Animation<double> interval(double begin, double end, Curve curve) {
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );
    }

    _markScale = Tween<double>(begin: 0.72, end: 1).animate(
      interval(0.0, 0.42, Curves.easeOutBack),
    );
    _markOpacity = interval(0.0, 0.24, Curves.easeOut);
    _markRotation = Tween<double>(begin: -0.12, end: 0).animate(
      interval(0.0, 0.5, Curves.easeOutCubic),
    );
    _shine = interval(0.35, 0.85, Curves.easeInOutCubic);
    _wordmarkOpacity = interval(0.18, 0.55, Curves.easeOut);
    _wordmarkOffset = Tween<double>(begin: 16, end: 0).animate(
      interval(0.18, 0.55, Curves.easeOutCubic),
    );
    _subtitleOpacity = interval(0.3, 0.65, Curves.easeOut);
    _progress = interval(0.05, 0.95, Curves.easeOutCubic);
    _ambient = interval(0.0, 0.7, Curves.easeOut);

    _controller.forward();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await Future.delayed(SplashScreen.totalDuration);

    if (!mounted) return;

    await ref.read(authNotifierProvider.notifier).checkAuthStatus();
    final authState = ref.read(authNotifierProvider);
    final cacheService = ref.read(localCacheServiceProvider);

    if (!mounted) return;

    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else if (authState.status == AuthStatus.needsEmailVerification) {
      context.go(AppRoutes.verifyEmail);
    } else {
      if (!cacheService.hasSeenOnboarding) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Ambient glow — memberi kedalaman tanpa mengganggu fokus logo.
          _AmbientGlow(animation: _ambient),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BrandTicketMark(
                    scale: _markScale,
                    opacity: _markOpacity,
                    rotation: _markRotation,
                    shine: _shine,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _wordmarkOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _wordmarkOffset.value),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TEMUKAMPUS',
                              style: AppTypography.hero.copyWith(
                                fontSize: 26,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 10),
                              decoration: const BoxDecoration(
                                color: AppColors.signal,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Text(
                            'Universitas Mercu Buana',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.ink500,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  _LoadingBar(progress: _progress),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.xxl,
            child: Opacity(
              opacity: _subtitleOpacity.value,
              child: Text(
                'v1.0.0 · Aplikasi Resmi Mahasiswa UMB',
                textAlign: TextAlign.center,
                style: AppTypography.micro.copyWith(
                  fontSize: 9.5,
                  color: AppColors.ink400,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo berbentuk tiket dengan kilau yang menyapu permukaannya.
class _BrandTicketMark extends StatelessWidget {
  final Animation<double> scale;
  final Animation<double> opacity;
  final Animation<double> rotation;
  final Animation<double> shine;

  const _BrandTicketMark({
    required this.scale,
    required this.opacity,
    required this.rotation,
    required this.shine,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scale, opacity, rotation, shine]),
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value.clamp(0, 1),
          child: Transform.rotate(
            angle: rotation.value,
            child: Transform.scale(scale: scale.value, child: child),
          ),
        );
      },
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          children: [
            TicketContainer(
              width: 96,
              height: 96,
              punchRadius: 9,
              punchPositionPercent: 0.58,
              borderRadius: 26,
              color: AppColors.cobalt,
              borderColor: AppColors.ink,
              borderWidth: 2,
              hasShadow: true,
              shadowOffset: const Offset(4, 4),
              child: const Center(
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
            // Kilau
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: AppRadii.borderXl,
                  child: AnimatedBuilder(
                    animation: shine,
                    builder: (context, _) {
                      final t = shine.value;
                      return Transform.translate(
                        offset: Offset(-120 + t * 260, 0),
                        child: Transform.rotate(
                          angle: 0.35,
                          child: Container(
                            width: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.35),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Titik sinyal khas TemuKampus
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final Animation<double> progress;

  const _LoadingBar({required this.progress});

  static const double width = 168;
  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.ink100,
            borderRadius: AppRadii.borderPill,
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: width * progress.value,
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cobalt, AppColors.signal],
              ),
              borderRadius: AppRadii.borderPill,
            ),
          ),
        );
      },
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Animation<double> animation;

  const _AmbientGlow({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -90 - t * 20,
                left: -80,
                child: _blob(
                  size: 300,
                  color: AppColors.cobalt.withValues(alpha: 0.10 * t),
                ),
              ),
              Positioned(
                bottom: -70 - t * 30,
                right: -90,
                child: _blob(
                  size: 280,
                  color: AppColors.signal.withValues(alpha: 0.12 * t),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}