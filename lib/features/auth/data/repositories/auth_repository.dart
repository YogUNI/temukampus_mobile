import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/image_compressor.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(remoteDataSource, storage);
});

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthRepository(this._remoteDataSource, this._storage);

  /// Masuk dengan login (NIM/Email) dan password
  Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(login: login, password: password);
    await _storage.saveAccessToken(response.token);
    await _storage.saveUserData(jsonEncode(response.user.toJson()));
    return response.user;
  }

  /// Pendaftaran Mahasiswa UMB
  Future<UserModel> registerUmb({
    required String name,
    required String email,
    required String phone,
    required String nim,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _remoteDataSource.registerUmb(
      name: name,
      email: email,
      phone: phone,
      nim: nim,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await _storage.saveAccessToken(response.token);
    await _storage.saveUserData(jsonEncode(response.user.toJson()));
    return response.user;
  }

  /// Pendaftaran Peserta Eksternal
  Future<UserModel> registerExternal({
    required String name,
    required String email,
    required String phone,
    required String institutionName,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _remoteDataSource.registerExternal(
      name: name,
      email: email,
      phone: phone,
      institutionName: institutionName,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await _storage.saveAccessToken(response.token);
    await _storage.saveUserData(jsonEncode(response.user.toJson()));
    return response.user;
  }

  /// Sinkronisasi profil pengguna terkini dari server
  Future<UserModel> syncCurrentUser() async {
    final user = await _remoteDataSource.getMe();
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  /// Mengambil data pengguna dari cache lokal terenkripsi jika ada
  Future<UserModel?> getCachedUser() async {
    final userJson = await _storage.getUserData();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Minta kode reset kata sandi.
  Future<String> forgotPassword(String email) {
    return _remoteDataSource.forgotPassword(email);
  }

  /// Reset kata sandi dengan kode dari email.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) {
    return _remoteDataSource.resetPassword(
      email: email,
      code: code,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  /// Perbarui profil lalu simpan salinan terbaru ke penyimpanan aman.
  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? institutionName,
  }) async {
    final user = await _remoteDataSource.updateProfile(
      name: name,
      phone: phone,
      institutionName: institutionName,
    );
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  /// Ganti kata sandi akun.
  Future<String> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _remoteDataSource.updatePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  /// Unggah foto profil baru.
  Future<UserModel> uploadAvatar(PickedImageData image) async {
    final user = await _remoteDataSource.uploadAvatar(image);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  /// Hapus foto profil.
  Future<UserModel> removeAvatar() async {
    final user = await _remoteDataSource.removeAvatar();
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  /// Memeriksa apakah token akses tersimpan
  Future<bool> hasValidToken() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Verifikasi kode 6 angka email
  Future<String> verifyEmailCode(String code) async {
    return await _remoteDataSource.verifyEmailCode(code);
  }

  /// Kirim ulang kode verifikasi email
  Future<String> resendEmailCode() async {
    return await _remoteDataSource.resendEmailCode();
  }

  /// Keluar akun (menghapus token server & storage)
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _storage.clearAll();
  }
}
