import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/session_expiry.dart';
import '../features/auth/presentation/controllers/auth_notifier.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Menyambungkan interceptor 401 ke pengelola sesi.
///
/// Dibangun sekali oleh widget root; tidak ada lapisan jaringan yang mengimpor
/// fitur auth, jadi tidak ada siklus provider.
final sessionBridgeProvider = Provider<void>((ref) {
  SessionExpiry.register(() => ref.read(authNotifierProvider.notifier).handleSessionExpired());
});

/// Root widget aplikasi TemuKampus Mobile terintegrasi dengan GoRouter.
class TemuKampusApp extends ConsumerWidget {
  const TemuKampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionBridgeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TemuKampus Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
