import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temukampus_mobile/app/app.dart';
import 'package:temukampus_mobile/core/storage/local_cache_service.dart';
import 'package:temukampus_mobile/core/storage/secure_storage_service.dart';
import 'package:temukampus_mobile/core/utils/formatters.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/splash_screen.dart';

import 'auth_notifier_test.dart';

/// Boot aplikasi lalu lewati splash. Dengan `has_seen_onboarding` = true,
/// rute akhirnya adalah /login.
Future<void> _pumpToLogin(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({'tk_has_seen_onboarding': true});
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

  await tester.pump(SplashScreen.totalDuration + const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  /// Ketuk sebuah teks, gulir dulu agar pasti terlihat di layar sempit.
  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('Layar Masuk', () {
    testWidgets('menampilkan brand, field, dan aksi utama', (tester) async {
      await _pumpToLogin(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Selamat Datang di TemuKampus'), findsOneWidget);
      expect(find.text('NIM atau Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);
      expect(find.text('Jelajahi sebagai Tamu'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('validasi kosong menempel di field masing-masing',
        (tester) async {
      await _pumpToLogin(tester);

      await tapText(tester, 'Masuk Sekarang');

      expect(find.text('NIM atau email wajib diisi.'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    });

    testWidgets('tidak overflow di layar sempit 360dp', (tester) async {
      await _pumpToLogin(tester, size: const Size(360, 780));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Layar Daftar', () {
    testWidgets('bisa dibuka dari tautan di layar masuk', (tester) async {
      await _pumpToLogin(tester);

      await tapText(tester, 'Daftar Akun Baru');

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Buat Akun TemuKampus'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ganti jenis akun menukar field NIM dengan institusi',
        (tester) async {
      await _pumpToLogin(tester);
      await tapText(tester, 'Daftar Akun Baru');

      expect(find.text('Nomor Induk Mahasiswa (NIM)'), findsOneWidget);
      expect(find.text('Nama Asal Kampus / Institusi'), findsNothing);

      await tapText(tester, 'Peserta Umum');

      expect(find.text('Nomor Induk Mahasiswa (NIM)'), findsNothing);
      expect(find.text('Nama Asal Kampus / Institusi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pratinjau NIM menampilkan prodi & angkatan', (tester) async {
      await _pumpToLogin(tester);
      await tapText(tester, 'Daftar Akun Baru');

      final nimField =
          find.widgetWithText(TextFormField, '11 digit, misal 41524010001');
      await tester.ensureVisible(nimField);
      await tester.pumpAndSettle();
      await tester.enterText(nimField, '41524010001');
      await tester.pumpAndSettle();

      expect(find.text('Teknik Informatika'), findsOneWidget);
      expect(find.text('Angkatan: 2024'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tidak overflow di layar sempit 360dp', (tester) async {
      await _pumpToLogin(tester, size: const Size(360, 780));
      await tapText(tester, 'Daftar Akun Baru');

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}