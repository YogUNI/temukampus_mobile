import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/core/storage/secure_storage_service.dart';
import 'package:temukampus_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:temukampus_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:temukampus_mobile/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:temukampus_mobile/features/auth/presentation/controllers/auth_state.dart';

// In-memory fake secure storage for unit testing
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
  }) async {
    return _store[key];
  }

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
  late AuthRepository authRepository;
  late SecureStorageService storageService;

  setUp(() {
    final fakeStorage = FakeSecureStorage();
    storageService = SecureStorageService(storage: fakeStorage);
    final apiClient = ApiClient(Dio());
    final remoteDataSource = AuthRemoteDataSource(apiClient);
    authRepository = AuthRepository(remoteDataSource, storageService);
    authNotifier = AuthNotifier(authRepository);
  });

  group('AuthNotifier State Machine Tests', () {
    test('Kondisi awal state adalah initial', () {
      expect(authNotifier.state.status, equals(AuthStatus.initial));
    });

    test('checkAuthStatus tanpa token mengubah status ke unauthenticated', () async {
      await authNotifier.checkAuthStatus();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
    });

    test('login Mahasiswa UMB dengan mock fallback berhasil authenticated', () async {
      final success = await authNotifier.login(
        login: '41524010001',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.name, equals('Yoga Gustira'));
      expect(authNotifier.state.user?.nim, equals('41524010001'));
      expect(authNotifier.state.user?.academicSummary, equals("Teknik Informatika '24"));
    });

    test('login akun suspended mendeteksi status suspended dan menyimpan alasan', () async {
      final success = await authNotifier.login(
        login: '41524010999',
        password: 'Password123!',
      );

      expect(success, isFalse);
      expect(authNotifier.state.status, equals(AuthStatus.suspended));
      expect(authNotifier.state.isSuspended, isTrue);
      expect(authNotifier.state.errorMessage, contains('dinonaktifkan sementara'));
    });

    test('registerUmb berhasil dan meminta verifikasi email', () async {
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
    });

    test('verifyEmail dengan kode 6 digit berhasil mengubah status ke authenticated', () async {
      // Registrasi terlebih dahulu
      await authNotifier.registerUmb(
        name: 'Budi Santoso',
        email: 'budi@mercubuana.ac.id',
        phone: '081234567890',
        nim: '41524010099',
        password: 'Password123!',
        passwordConfirmation: 'Password123!',
      );

      // Verifikasi kode
      final verified = await authNotifier.verifyEmail('123456');
      expect(verified, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.emailVerified, isTrue);
    });

    test('logout menghapus token dan mengubah status ke unauthenticated', () async {
      // Login dulu
      await authNotifier.login(login: '41524010001', password: 'Password123!');
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));

      // Logout
      await authNotifier.logout();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(await storageService.getAccessToken(), isNull);
    });
  });
}

