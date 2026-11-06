import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temukampus_mobile/app/app.dart';
import 'package:temukampus_mobile/core/storage/local_cache_service.dart';
import 'package:temukampus_mobile/core/storage/secure_storage_service.dart';
import 'package:temukampus_mobile/core/utils/formatters.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'auth_notifier_test.dart';

void main() {
  testWidgets('TemuKampusApp router smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'tk_has_seen_onboarding': true});
    await AppFormatters.initialize();
    final sharedPreferences = await SharedPreferences.getInstance();
    final fakeStorage = FakeSecureStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          secureStorageServiceProvider.overrideWithValue(
            SecureStorageService(storage: fakeStorage),
          ),
        ],
        child: const TemuKampusApp(),
      ),
    );

    // Verifikasi branding TemuKampus tampil di SplashScreen awal
    expect(find.text('TEMUKAMPUS'), findsOneWidget);
    expect(find.text('Universitas Mercu Buana'), findsOneWidget);

    // Majukan waktu melewati durasi splash dan microtasks async
    await tester.pump(SplashScreen.totalDuration + const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verifikasi layar login muncul setelah splash
    expect(find.text('Selamat Datang di TemuKampus'), findsOneWidget);
    expect(find.text('NIM atau Alamat Email'), findsOneWidget);
  });
}
