import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../controllers/auth_notifier.dart';
import '../controllers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Jeda animasi logo splash 1.2 detik
    await Future.delayed(const Duration(milliseconds: 1200));

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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.cobalt,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                    Positioned(
                      top: 18,
                      right: 18,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.signal,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
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
                      const SizedBox(width: 4),
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
                  const SizedBox(height: 6),
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
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cobalt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
