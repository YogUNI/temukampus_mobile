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
import '../../features/registration/presentation/screens/registration_screen.dart';
import '../../features/scanner/presentation/screens/event_gate_selector_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/tickets/presentation/screens/my_tickets_screen.dart';
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart';
import '../shell/main_scaffold.dart';
import 'route_names.dart';

CustomTransitionPage<void> _buildSlideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Transisi "bloom": fade + skala halus dengan veil putih. Dipakai untuk rute
/// pertama setelah splash (onboarding/login) agar perpindahan terasa menyatu
/// dengan flash putih di akhir splash — bukan menggeser halaman.
CustomTransitionPage<void> _buildFadeScaleTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final veil = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      );
      return AnimatedBuilder(
        animation: veil,
        builder: (context, inner) => Stack(
          children: [
            inner!,
            // Veil putih menyusut: layar baru "muncul" dari putih.
            IgnorePointer(
              child: Container(
                color: Colors.white.withValues(
                  alpha: (1 - veil.value).clamp(0.0, 1.0) * 0.95,
                ),
              ),
            ),
          ],
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.uri.path;

      final isOnboarding = location == AppRoutes.onboarding;
      final isLogin = location == AppRoutes.login;
      final isRegister = location == AppRoutes.register;
      final isVerifyEmail = location == AppRoutes.verifyEmail;

      // 1. Sedang memuat sesi awal
      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.authenticating) {
        return null; // Tetap di rute saat ini
      }

      // 2. Akun butuh verifikasi email
      if (authState.status == AuthStatus.needsEmailVerification) {
        return isVerifyEmail ? null : AppRoutes.verifyEmail;
      }

      // 3. User belum terotentikasi (Guest Mode vs Protected Routes)
      if (authState.status == AuthStatus.unauthenticated || authState.status == AuthStatus.suspended) {
        // Rute registrasi ACARA wajib login. Catatan: '/register' milik layar
        // Daftar Akun bukan termasuk — kalau ikut dicocokkan, tamu tidak akan
        // pernah bisa membuka halaman pendaftaran akun.
        final isEventRegistrationRoute =
            location.endsWith('/register') && !isRegister;
        final isTicketDetailRoute = location.startsWith('/tickets/');
        final isScannerRoute = location.startsWith('/scanner');

        if (isEventRegistrationRoute) {
          final encodedRedirect = Uri.encodeComponent(location);
          return '${AppRoutes.login}?redirect=$encodedRedirect&reason=register';
        }

        if (isTicketDetailRoute) {
          final encodedRedirect = Uri.encodeComponent(location);
          return '${AppRoutes.login}?redirect=$encodedRedirect';
        }

        if (isScannerRoute) {
          return AppRoutes.login;
        }

        // Rute publik lainnya (Home, Explore, Event Detail, Tabs) diizinkan dalam Mode Tamu (Guest)
        return null;
      }

      // 4. User sudah login aktif
      if (authState.status == AuthStatus.authenticated) {
        if (isLogin || isRegister || isOnboarding || isVerifyEmail) {
          final redirect = state.uri.queryParameters['redirect'];
          if (redirect != null && redirect.isNotEmpty) {
            return Uri.decodeComponent(redirect);
          }
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
        pageBuilder: (context, state) => _buildFadeScaleTransition(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildFadeScaleTransition(
          state: state,
          child: LoginScreen(
            redirectUrl: state.uri.queryParameters['redirect'] != null
                ? Uri.decodeComponent(state.uri.queryParameters['redirect']!)
                : null,
            loginReason: state.uri.queryParameters['reason'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _buildSlideTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        pageBuilder: (context, state) => _buildSlideTransition(
          state: state,
          child: const VerifyEmailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return _buildSlideTransition(
            state: state,
            child: EventDetailScreen(slug: slug),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.eventRegister,
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return _buildSlideTransition(
            state: state,
            child: RegistrationScreen(slug: slug),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ticketDetail,
        pageBuilder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return _buildSlideTransition(
            state: state,
            child: TicketDetailScreen(ticketCode: code),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scannerSelectEvent,
        pageBuilder: (context, state) => _buildSlideTransition(
          state: state,
          child: const EventGateSelectorScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.scannerGate,
        pageBuilder: (context, state) {
          final eventIdStr = state.pathParameters['eventId'] ?? '1';
          final eventId = int.tryParse(eventIdStr) ?? 1;
          return _buildSlideTransition(
            state: state,
            child: ScannerScreen(eventId: eventId),
          );
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

