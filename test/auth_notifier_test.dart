import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temukampus_mobile/core/utils/image_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/storage/secure_storage_service.dart';
import 'package:temukampus_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:temukampus_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:temukampus_mobile/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:temukampus_mobile/features/auth/presentation/controllers/auth_state.dart';

import 'helpers/fake_api.dart';

/// Penyimpanan aman palsu (tanpa platform channel).
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }
}

void main() {
  late AuthNotifier authNotifier;
  late SecureStorageService storageService;
  late FakeApiAdapter adapter;

  /// Seluruh respons memakai fixture hasil rekaman API v1 sungguhan.
  void buildNotifier({Map<String, dynamic>? loginBody, int loginStatus = 200}) {
    adapter = FakeApiAdapter([
      FakeRoute(
        method: 'POST',
        path: '/auth/login',
        body: loginBody ?? apiFixture('auth_login.json'),
        status: loginStatus,
      ),
      FakeRoute(
        method: 'POST',
        path: '/auth/register',
        body: apiFixture('auth_register.json'),
        status: 201,
      ),
      FakeRoute(
        method: 'POST',
        path: '/auth/verify-email-code',
        body: apiFixture('auth_verify_email.json'),
      ),
      FakeRoute(method: 'POST', path: '/auth/resend-email-code', body: {
        'success': true,
        'message': 'Kode verifikasi baru telah dikirimkan ke emailmu.',
      }),
      FakeRoute(method: 'POST', path: '/auth/logout', body: apiFixture('auth_logout.json')),
      FakeRoute(method: 'GET', path: '/auth/me', body: apiFixture('auth_me.json')),
      FakeRoute(
        method: 'POST',
        path: '/auth/forgot-password',
        body: apiFixture('forgot_password.json'),
      ),
      FakeRoute(method: 'POST', path: '/auth/reset-password', body: apiFixture('reset_password.json')),
      FakeRoute(method: 'GET', path: '/profile', body: apiFixture('profile_show.json')),
      FakeRoute(method: 'PUT', path: '/profile', body: apiFixture('profile_update.json')),
      FakeRoute(method: 'PUT', path: '/profile/password', body: apiFixture('profile_password.json')),
      FakeRoute(method: 'POST', path: '/profile/avatar', body: apiFixture('profile_avatar.json')),
      FakeRoute(
        method: 'DELETE',
        path: '/profile/avatar',
        body: {'success': true, 'message': 'Foto profil dihapus.', 'data': apiFixture('profile_show.json')['data']},
      ),
    ]);

    storageService = SecureStorageService(storage: FakeSecureStorage());
    final remoteDataSource = AuthRemoteDataSource(fakeApiClient(adapter));
    authNotifier = AuthNotifier(AuthRepository(remoteDataSource, storageService));
  }

  setUp(buildNotifier);

  group('AuthNotifier State Machine Tests', () {
    test('Kondisi awal state adalah initial', () {
      expect(authNotifier.state.status, equals(AuthStatus.initial));
    });

    test('checkAuthStatus tanpa token mengubah status ke unauthenticated', () async {
      await authNotifier.checkAuthStatus();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
    });

    test('login memakai respons API nyata dan menyimpan token', () async {
      final success = await authNotifier.login(
        login: 'peserta1@example.test',
        password: 'password',
      );

      expect(success, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.name, equals('Peserta 1'));
      expect(authNotifier.state.user?.nim, equals('41521000001'));
      expect(authNotifier.state.user?.studyProgram?.name, equals('Teknik Sipil'));
      expect(authNotifier.state.user?.cohortYear, equals(2021));
      expect(await storageService.getAccessToken(), equals('test-token'));
      expect(adapter.requests, contains('POST /auth/login'));
    });

    test('login akun ditangguhkan menampilkan status suspended + alasan', () async {
      buildNotifier(loginBody: apiFixture('auth_suspended.json'), loginStatus: 403);

      final success = await authNotifier.login(
        login: 'peserta1@example.test',
        password: 'password',
      );

      expect(success, isFalse);
      expect(authNotifier.state.status, equals(AuthStatus.suspended));
      expect(authNotifier.state.isSuspended, isTrue);
      expect(authNotifier.state.errorMessage, contains('dinonaktifkan sementara'));
      expect(await storageService.getAccessToken(), isNull);
    });

    test('login dengan kredensial salah menempelkan galat pada field login', () async {
      buildNotifier(loginBody: apiFixture('auth_login_invalid.json'), loginStatus: 422);

      final success = await authNotifier.login(
        login: 'salah@example.test',
        password: 'salah123',
      );

      expect(success, isFalse);
      expect(authNotifier.state.status, equals(AuthStatus.error));
      expect(authNotifier.state.firstErrorFor('login'), isNotNull);
    });

    test('registerUmb meminta verifikasi email', () async {
      final success = await authNotifier.registerUmb(
        name: 'Mahasiswa Baru',
        email: 'maba@mercubuana.ac.id',
        phone: '081299998888',
        nim: '41824010055',
        password: 'Password123!',
        passwordConfirmation: 'Password123!',
      );

      expect(success, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.needsEmailVerification));
      expect(authNotifier.state.user?.email, equals('maba@mercubuana.ac.id'));
      expect(await storageService.getAccessToken(), equals('test-token'));
    });

    test('verifyEmail mengubah status ke authenticated', () async {
      await authNotifier.registerUmb(
        name: 'Mahasiswa Baru',
        email: 'maba@mercubuana.ac.id',
        phone: '081299998888',
        nim: '41824010055',
        password: 'Password123!',
        passwordConfirmation: 'Password123!',
      );

      final verified = await authNotifier.verifyEmail('123456');

      expect(verified, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.emailVerified, isTrue);
      expect(adapter.requests, contains('POST /auth/verify-email-code'));
    });

    test('logout menghapus token dan mengubah status ke unauthenticated', () async {
      await authNotifier.login(login: 'peserta1@example.test', password: 'password');
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));

      await authNotifier.logout();

      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(await storageService.getAccessToken(), isNull);
      expect(adapter.requests, contains('POST /auth/logout'));
    });

    test('handleSessionExpired mengembalikan pengguna ke login dengan pesan jelas', () {
      authNotifier.handleSessionExpired();

      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.errorMessage, contains('Sesi Anda telah berakhir'));
    });
  });

  group('Profil pengguna (API v1)', () {
    test('updateProfile memperbarui state & penyimpanan', () async {
      await authNotifier.login(login: 'peserta1@example.test', password: 'password');

      final error = await authNotifier.updateProfile(
        name: 'Nama Setelah Ubah',
        phone: '081298765432',
      );

      expect(error, isNull);
      expect(authNotifier.state.user?.name, equals('Nama Setelah Ubah'));
      expect(adapter.requests, contains('PUT /profile'));
    });

    test('changePassword mengirim kata sandi saat ini & konfirmasi', () async {
      final error = await authNotifier.changePassword(
        currentPassword: 'Rahasia123',
        newPassword: 'Rahasia456',
        confirmation: 'Rahasia456',
      );

      expect(error, isNull);
      expect(adapter.requests, contains('PUT /profile/password'));
    });

    test('changePassword salah menampilkan pesan dari server', () async {
      buildNotifier();
      adapter = FakeApiAdapter([
        FakeRoute(
          method: 'PUT',
          path: '/profile/password',
          body: apiFixture('profile_password_invalid.json'),
          status: 422,
        ),
      ]);
      final remoteDataSource = AuthRemoteDataSource(fakeApiClient(adapter));
      authNotifier = AuthNotifier(AuthRepository(remoteDataSource, storageService));

      final error = await authNotifier.changePassword(
        currentPassword: 'SalahBanget1',
        newPassword: 'Rahasia789',
        confirmation: 'Rahasia789',
      );

      expect(error, contains('Password saat ini'));
    });

    test('updateAvatar menyimpan URL foto baru ke state', () async {
      await authNotifier.login(login: 'peserta1@example.test', password: 'password');
      final before = authNotifier.state.user?.avatarUrl;

      final error = await authNotifier.updateAvatar(
        PickedImageData(
          file: XFile('avatar.png'),
          bytes: Uint8List.fromList([1, 2, 3]),
          sizeInBytes: 3,
          fileName: 'avatar.png',
        ),
      );

      expect(error, isNull);
      expect(authNotifier.state.user?.avatarUrl, isNotNull);
      expect(authNotifier.state.user?.avatarUrl, isNot(before));
    });
  });

  group('Lupa kata sandi (API v1)', () {
    test('requestPasswordReset mengirim permintaan & tidak membocorkan status email', () async {
      final error = await authNotifier.requestPasswordReset('peserta1@example.test');

      expect(error, isNull);
      expect(adapter.requests, contains('POST /auth/forgot-password'));
    });

    test('resetPassword dengan kode benar berhasil', () async {
      final error = await authNotifier.resetPassword(
        email: 'peserta1@example.test',
        code: '503823',
        newPassword: 'BaruSekali456',
        confirmation: 'BaruSekali456',
      );

      expect(error, isNull);
      expect(adapter.requests, contains('POST /auth/reset-password'));
    });

    test('kode salah menampilkan pesan dari server', () async {
      buildNotifier();
      adapter = FakeApiAdapter([
        FakeRoute(
          method: 'POST',
          path: '/auth/reset-password',
          body: apiFixture('reset_password_invalid.json'),
          status: 422,
        ),
      ]);
      final remoteDataSource = AuthRemoteDataSource(fakeApiClient(adapter));
      authNotifier = AuthNotifier(AuthRepository(remoteDataSource, storageService));

      final error = await authNotifier.resetPassword(
        email: 'peserta1@example.test',
        code: '000000',
        newPassword: 'BaruSekali456',
        confirmation: 'BaruSekali456',
      );

      expect(error, contains('Kode'));
    });
  });
}
