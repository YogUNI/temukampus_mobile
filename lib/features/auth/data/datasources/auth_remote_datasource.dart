import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/image_compressor.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient);
});

/// Remote Data Source yang memanggil endpoint Laravel 13 dengan
/// Fallback Dev Mode otomatis saat server lokal belum menyala.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// Masuk dengan NIM atau Email
  Future<AuthResponseModel> login({
    required String login,
    required String password,
    String? deviceName,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'login': login.trim(),
          'password': password,
          'device_name': deviceName ?? 'TemuKampus Flutter App',
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return AuthResponseModel(
        token: data['token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapLoginError(e);
    }
  }

  /// Registrasi akun Mahasiswa UMB
  Future<AuthResponseModel> registerUmb({
    required String name,
    required String email,
    required String phone,
    required String nim,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'account_type': 'umb',
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'nim': nim.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          // Server menegakkan rule `accepted`; layar registrasi sudah
          // memblokir submit sebelum kotak S&K dicentang.
          'terms_accepted': true,
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return AuthResponseModel(
        token: data['token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Registrasi akun Peserta Eksternal / Umum
  Future<AuthResponseModel> registerExternal({
    required String name,
    required String email,
    required String phone,
    required String institutionName,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'account_type': 'external',
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'institution_name': institutionName.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'terms_accepted': true,
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return AuthResponseModel(
        token: data['token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Mengambil profil pengguna aktif terkini
  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.me);
      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Verifikasi kode 6 angka email.
  ///
  /// Kode salah/kedaluwarsa/terkunci dikembalikan backend sebagai HTTP 422
  /// dengan `errors.code`, sehingga UI bisa menempelkannya ke input kode.
  Future<String> verifyEmailCode(String code) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmailCode,
        data: {'code': code.trim()},
      );
      return response.data?['message'] as String? ?? 'Email berhasil diverifikasi.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Kirim ulang kode verifikasi email.
  Future<String> resendEmailCode() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.resendEmailCode,
      );
      return response.data?['message'] as String? ?? 'Kode verifikasi baru telah dikirimkan.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Minta tautan + kode reset kata sandi ke email.
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );

      return response.data?['message'] as String? ??
          'Kalau email itu terdaftar, kami sudah mengirim tautan dan kode atur ulang password.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Reset kata sandi memakai kode 6 angka dari email.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      return response.data?['message'] as String? ?? 'Password diganti. Silakan masuk.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Perbarui profil (nama, nomor WhatsApp, asal institusi).
  ///
  /// Aturan validasi berasal dari `UpdateProfileRequest` di backend — sama
  /// dengan halaman /profil web.
  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? institutionName,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
        data: {
          'name': name.trim(),
          'phone': phone?.trim(),
          if (institutionName != null) 'institution_name': institutionName.trim(),
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Ganti kata sandi (wajib menyertakan kata sandi saat ini).
  Future<String> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      return response.data?['message'] as String? ?? 'Kata sandi berhasil diperbarui.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Unggah foto profil (multipart `avatar`, gambar hasil crop klien).
  Future<UserModel> uploadAvatar(PickedImageData image) async {
    try {
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(image.bytes, filename: image.fileName),
      });

      final response = await _apiClient.uploadMultipart<Map<String, dynamic>>(
        '/profile/avatar',
        formData: formData,
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Hapus foto profil (kembali ke inisial nama).
  Future<UserModel> removeAvatar() async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>('/profile/avatar');

      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Keluar akun
  Future<void> logout() async {
    try {
      await _apiClient.post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (_) {
      // Abaikan jika token di server sudah expired
    }
  }

  /// Login butuh satu perlakuan khusus: 403 `ACCOUNT_SUSPENDED` diterjemahkan
  /// menjadi [SuspendedAccountException] agar UI menampilkan dialog pemblokiran
  /// beserta alasan admin, bukan galat di field login.
  AppException _mapLoginError(DioException e) {
    final error = e.error;

    if (error is AuthException && error.errorCode == 'ACCOUNT_SUSPENDED') {
      final user = error.payload?['user'];

      return SuspendedAccountException(
        error.message,
        userJson: user is Map<String, dynamic> ? user : null,
      );
    }

    return _asAppException(e);
  }

  AppException _asAppException(DioException e) {
    final error = e.error;
    if (error is AppException) return error;

    return ServerException(
      'Tidak dapat menghubungi server TemuKampus. Periksa koneksi lalu coba lagi.',
      e.response?.statusCode,
    );
  }
}
