import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temukampus_mobile/app/app.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/core/storage/local_cache_service.dart';
import 'package:temukampus_mobile/core/storage/secure_storage_service.dart';
import 'package:temukampus_mobile/core/utils/formatters.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:temukampus_mobile/features/auth/presentation/widgets/auth_success_overlay.dart';

import 'auth_notifier_test.dart';
import 'helpers/fake_api.dart';

/// Boot aplikasi lalu lewati splash. Dengan `has_seen_onboarding` = true,
/// rute akhirnya adalah /login.
Future<void> _pumpToLogin(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  List<Override> extraOverrides = const [],
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
        ...extraOverrides,
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
      expect(find.text('Angkatan 2024'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pratinjau NIM memakai prodi yang benar untuk kode 411',
        (tester) async {
      await _pumpToLogin(tester);
      await tapText(tester, 'Daftar Akun Baru');

      final nimField =
          find.widgetWithText(TextFormField, '11 digit, misal 41524010001');
      await tester.ensureVisible(nimField);
      await tester.pumpAndSettle();
      await tester.enterText(nimField, '41124010001');
      await tester.pumpAndSettle();

      // Regresi: 411 = Teknik Sipil menurut database, bukan Teknik Arsitektur.
      expect(find.text('Teknik Sipil'), findsOneWidget);
      expect(find.text('Fakultas Teknik'), findsOneWidget);
      expect(find.text('Angkatan 2024'), findsOneWidget);
    });

    testWidgets('kode prodi tak dikenal memunculkan peringatan, bukan blokir',
        (tester) async {
      await _pumpToLogin(tester);
      await tapText(tester, 'Daftar Akun Baru');

      final nimField =
          find.widgetWithText(TextFormField, '11 digit, misal 41524010001');
      await tester.ensureVisible(nimField);
      await tester.pumpAndSettle();
      await tester.enterText(nimField, '99924010001');
      await tester.pumpAndSettle();

      expect(find.textContaining('belum terdaftar'), findsOneWidget);
      // Kode prodi adalah urusan internal backend, tidak ditampilkan ke pendaftar.
      expect(find.textContaining('Kode:'), findsNothing);
      expect(find.text('Angkatan 2024'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tidak overflow di layar sempit 360dp', (tester) async {
      await _pumpToLogin(tester, size: const Size(360, 780));
      await tapText(tester, 'Daftar Akun Baru');

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Alur masuk end-to-end (API v1)', () {
    /// Adapter memakai fixture rekaman API nyata: login, katalog, kategori.
    FakeApiAdapter buildAdapter() => FakeApiAdapter([
          FakeRoute(method: 'POST', path: '/auth/login', body: apiFixture('auth_login.json')),
          FakeRoute(method: 'GET', path: '/auth/me', body: apiFixture('auth_me.json')),
          FakeRoute(method: 'GET', path: '/events', body: apiFixture('events_index.json')),
          FakeRoute(method: 'GET', path: '/categories', body: apiFixture('categories.json')),
        ]);

    testWidgets('animasi sukses tampil sebelum berpindah ke beranda',
        (tester) async {
      final adapter = buildAdapter();
      await _pumpToLogin(
        tester,
        extraOverrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      );

      await tester.enterText(find.byType(TextField).at(0), 'peserta1@example.test');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Layar sukses muncul sebagai jeda yang disengaja sebelum beranda.
      expect(find.byType(AuthSuccessOverlay), findsOneWidget);
      expect(find.text('Berhasil Masuk'), findsOneWidget);

      // Setelah animasi selesai, overlay hilang dan beranda tampil.
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(AuthSuccessOverlay), findsNothing);
      expect(find.text('Halo, Peserta!'), findsOneWidget);
    });

    testWidgets('mengisi form, masuk, lalu beranda menyapa nama pengguna', (tester) async {
      final adapter = buildAdapter();
      await _pumpToLogin(
        tester,
        extraOverrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      );

      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'peserta1@example.test');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.pumpAndSettle();

      await tapText(tester, 'Masuk Sekarang');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Token tersimpan & permintaan login benar-benar dikirim.
      expect(adapter.requests, contains('POST /auth/login'));

      // Beranda menyapa dengan nama depan dari respons API.
      expect(find.text('Halo, Peserta!'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('kredensial salah menempelkan pesan galat pada field', (tester) async {
      final adapter = FakeApiAdapter([
        FakeRoute(
          method: 'POST',
          path: '/auth/login',
          body: apiFixture('auth_login_invalid.json'),
          status: 422,
        ),
        FakeRoute(method: 'GET', path: '/events', body: apiFixture('events_index.json')),
        FakeRoute(method: 'GET', path: '/categories', body: apiFixture('categories.json')),
      ]);

      await _pumpToLogin(
        tester,
        extraOverrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      );

      await tester.enterText(find.byType(TextField).at(0), 'salah@example.test');
      await tester.enterText(find.byType(TextField).at(1), 'salah123');
      await tester.pumpAndSettle();

      await tapText(tester, 'Masuk Sekarang');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('NIM/email atau kata sandi salah'), findsWidgets);
    });
  });

  group('Lupa kata sandi (layar dua langkah)', () {
    testWidgets('kirim kode lalu simpan kata sandi baru kembali ke login', (tester) async {
      final adapter = FakeApiAdapter([
        FakeRoute(
          method: 'POST',
          path: '/auth/forgot-password',
          body: apiFixture('forgot_password.json'),
        ),
        FakeRoute(method: 'POST', path: '/auth/reset-password', body: apiFixture('reset_password.json')),
        FakeRoute(method: 'GET', path: '/events', body: apiFixture('events_index.json')),
        FakeRoute(method: 'GET', path: '/categories', body: apiFixture('categories.json')),
      ]);

      await _pumpToLogin(
        tester,
        extraOverrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      );

      // Buka layar lupa kata sandi dari tautan di form login.
      await tapText(tester, 'Lupa kata sandi?');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      // Langkah 1: email → kirim kode.
      await tester.enterText(find.byType(TextField).first, 'peserta1@example.test');
      await tester.pumpAndSettle();
      await tapText(tester, 'Kirim Kode');
      await tester.pumpAndSettle();

      expect(adapter.requests, contains('POST /auth/forgot-password'));
      expect(find.textContaining('Kode 6 angka sudah dikirim'), findsOneWidget);

      // Langkah 2: kode + kata sandi baru.
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4));

      await tester.enterText(fields.at(1), '503823');
      await tester.enterText(fields.at(2), 'BaruSekali456');
      await tester.enterText(fields.at(3), 'BaruSekali456');
      await tester.pumpAndSettle();

      await tapText(tester, 'Simpan Kata Sandi Baru');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(adapter.requests, contains('POST /auth/reset-password'));
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
