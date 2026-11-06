import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temukampus_mobile/app/app.dart';
import 'package:temukampus_mobile/core/storage/local_cache_service.dart';
import 'package:temukampus_mobile/core/storage/secure_storage_service.dart';
import 'package:temukampus_mobile/core/utils/formatters.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/splash_screen.dart';

import 'auth_notifier_test.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  bool seenOnboarding = false,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues(
    seenOnboarding ? {'tk_has_seen_onboarding': true} : {},
  );
  await AppFormatters.initialize();
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStorageServiceProvider.overrideWithValue(
          SecureStorageService(storage: FakeSecureStorage()),
        ),
      ],
      child: const TemuKampusApp(),
    ),
  );
}

void main() {
  group('Splash screen', () {
    testWidgets('brand langsung tampil di frame pertama (tanpa layout shift)',
        (tester) async {
      await _pumpApp(tester);

      expect(find.text('TEMUKAMPUS'), findsOneWidget);
      expect(find.text('Universitas Mercu Buana'), findsOneWidget);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Selesaikan splash agar tidak ada timer menggantung.
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
    });

    testWidgets('progress bar terisi mengikuti durasi splash', (tester) async {
      await _pumpApp(tester);

      // Cari bar progres (track 168x4 di dalam splash).
      final bar = find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(Container),
      );
      expect(bar, findsWidgets);

      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    });

    testWidgets('tidak overflow di layar sempit 360dp', (tester) async {
      await _pumpApp(tester, size: const Size(360, 780));

      expect(find.text('TEMUKAMPUS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
    });
  });

  group('Onboarding', () {
    testWidgets('setelah splash tampil slide pertama dengan brand & lewati',
        (tester) async {
      await _pumpApp(tester);
      await tester.pump(SplashScreen.totalDuration);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('TemuKampus'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.text('Temukan Seluruh Acara Kampus UMB'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol Lanjutkan memindah 3 slide lalu menampilkan dua CTA',
        (tester) async {
      await _pumpApp(tester);
      await tester.pump(SplashScreen.totalDuration);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar Cepat dengan Data Otomatis'), findsOneWidget);

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Tiket QR Code Anti Ribet Hari-H'), findsOneWidget);
      expect(find.text('Masuk dengan Akun UMB'), findsOneWidget);
      expect(find.text('Jelajahi Acara Dulu'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tidak overflow di 360dp pada semua slide', (tester) async {
      await _pumpApp(tester, size: const Size(360, 780));
      await tester.pump(SplashScreen.totalDuration);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}