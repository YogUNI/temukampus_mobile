import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Layanan enkripsi Keystore (Android) & Keychain (iOS) untuk menyimpan
/// token autentikasi Laravel Sanctum dan data sensitif pengguna.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  // === Access Token (Sanctum) ===

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
  }

  // === Refresh / Secondary Token ===

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.keyRefreshToken);
  }

  // === Cached User Data (JSON) ===

  Future<void> saveUserData(String jsonString) async {
    await _storage.write(key: AppConstants.keyUserData, value: jsonString);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.keyUserData);
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: AppConstants.keyUserData);
  }

  // === Global Clear (Saat Logout atau HTTP 401 Sesi Habis) ===

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

