import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../controllers/auth_notifier.dart';
import '../controllers/auth_state.dart';
import '../widgets/splash_scene.dart';

/// Splash sinematik TemuKampus.
///
/// Satu controller 3,6 detik menggerakkan seluruh timeline (lihat
/// [SplashTicketScene] untuk tabel fase scene). Navigasi dipicu tepat saat
/// controller selesai supaya tidak ada frame "diam" di antara splash dan layar
/// berikutnya.
///
/// Transisi masuk dan keluar memakai *veil* putih yang saling menyambung dengan
/// transisi rute (fade-through-white), sehingga splash → onboarding/login
/// terasa sebagai satu gerakan.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const Duration totalDuration = Duration(milliseconds: 3600);

  /// Porsi timeline untuk keluar (zoom-back + veil).
  static const double exitStart = 0.90;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _glow;
  late final Animation<double> _wordOpacity;
  late final Animation<double> _wordOffset;
  late final Animation<double> _wordScale;
  late final Animation<double> _dotPulse;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: SplashScreen.totalDuration,
    );

    Animation<double> at(double begin, double end, Curve curve) =>
        CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

    _glow = at(0.0, 0.5, Curves.easeOutCubic);
    _wordOpacity = at(0.50, 0.70, Curves.easeOut);
    _wordOffset = Tween<double>(begin: 18, end: 0).animate(
      at(0.50, 0.72, Curves.easeOutCubic),
    );
    _wordScale = Tween<double>(begin: 0.94, end: 1).animate(
      at(0.50, 0.78, Curves.elasticOut),
    );
    _dotPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.7, end: 1.0), weight: 60),
    ]).animate(at(0.60, 0.84, Curves.easeInOut));
    _progress = at(0.03, 0.88, Curves.easeInOutCubic);

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
    } else if (!cacheService.hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.login);
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
          const _SplashBackground(),
          _GlowLayer(animation: _glow),

          // Konten: Positioned.fill WAJIB supaya Column melebar penuh dan
          // scene benar-benar berada di tengah layar (bukan menempel kiri).
          Positioned.fill(
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  final exit = Curves.easeInCubic.transform(
                    ((t - SplashScreen.exitStart) / (1 - SplashScreen.exitStart))
                        .clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: 1 - exit,
                    child: Transform.scale(
                      scale: 1 - 0.06 * exit,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SplashTicketScene(progress: _controller),
                    const SizedBox(height: AppSpacing.lg),
                    _Wordmark(
                      controller: _controller,
                      opacity: _wordOpacity,
                      offset: _wordOffset,
                      scale: _wordScale,
                      dotPulse: _dotPulse,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _ProgressBlock(
                      controller: _controller,
                      progress: _progress,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),

          // Veil putih: menyambung masuk (fade-out) & keluar (fade-in).
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final entry = 1 - Curves.easeOut.transform((t / 0.10).clamp(0.0, 1.0));
              final exit = Curves.easeInCubic.transform(
                ((t - SplashScreen.exitStart) / (1 - SplashScreen.exitStart))
                    .clamp(0.0, 1.0),
              );
              final alpha = math.max(entry * 0.9, exit);
              if (alpha <= 0.001) return const SizedBox.shrink();
              return IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.paper, Color(0xFFEDF1FE), AppColors.paper],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _GlowLayer extends StatelessWidget {
  final Animation<double> animation;

  const _GlowLayer({required this.animation});

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
                top: -130 - t * 20,
                left: -120,
                child: _Glow(
                  size: 340,
                  color: AppColors.cobalt.withValues(alpha: 0.12 * t),
                ),
              ),
              Positioned(
                bottom: -120 - t * 24,
                right: -130,
                child: _Glow(
                  size: 320,
                  color: AppColors.signal.withValues(alpha: 0.13 * t),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
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

class _Wordmark extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> opacity;
  final Animation<double> offset;
  final Animation<double> scale;
  final Animation<double> dotPulse;

  const _Wordmark({
    required this.controller,
    required this.opacity,
    required this.offset,
    required this.scale,
    required this.dotPulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: opacity.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, offset.value),
          child: Transform.scale(scale: scale.value, child: child),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TEMUKAMPUS',
                style: AppTypography.hero.copyWith(
                  fontSize: 27,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedBuilder(
                animation: dotPulse,
                builder: (context, _) => Transform.scale(
                  scale: dotPulse.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 7),
                    decoration: const BoxDecoration(
                      color: AppColors.signal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Universitas Mercu Buana',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> progress;

  const _ProgressBlock({required this.controller, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        children: [
          _ProgressBar(progress: progress.value),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Menyiapkan pengalaman kampusmu…',
            style: AppTypography.micro.copyWith(
              fontSize: 9.5,
              color: AppColors.ink400,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  static const double width = 168;
  static const double height = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ink100,
        borderRadius: AppRadii.borderPill,
      ),
      alignment: Alignment.centerLeft,
      child: Container(
        width: width * progress.clamp(0.0, 1.0),
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.cobalt, AppColors.signal]),
          borderRadius: AppRadii.borderPill,
        ),
      ),
    );
  }
}