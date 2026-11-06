import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_notifier.dart';
import '../../features/auth/presentation/controllers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/explore_screen.dart';
import '../../features/events/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/tickets/presentation/screens/my_tickets_screen.dart';
import '../shell/main_scaffold.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.uri.path;

      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isLogin = location == AppRoutes.login;
      final isRegister = location == AppRoutes.register;
      final isVerifyEmail = location == AppRoutes.verifyEmail;

      final isPublicRoute = isSplash || isOnboarding || isLogin || isRegister;

      // 1. Sedang memuat sesi awal
      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.authenticating) {
        return null; // Tetap di rute saat ini
      }

      // 2. Akun butuh verifikasi email
      if (authState.status == AuthStatus.needsEmailVerification) {
        return isVerifyEmail ? null : AppRoutes.verifyEmail;
      }

      // 3. User belum terotentikasi
      if (authState.status == AuthStatus.unauthenticated || authState.status == AuthStatus.suspended) {
        if (!isPublicRoute) {
          return AppRoutes.login;
        }
        return null;
      }

      // 4. User sudah login aktif
      if (authState.status == AuthStatus.authenticated) {
        if (isLogin || isRegister || isOnboarding || isVerifyEmail) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      // Splash & Onboarding
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return EventDetailScreen(slug: slug);
        },
      ),

      // Main Navigation Shell (4 Tab Bawah)
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.explore,
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: AppRoutes.myTickets,
            builder: (context, state) => const MyTicketsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

