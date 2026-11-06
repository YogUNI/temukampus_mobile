import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/nim_parser.dart';
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
    } on NetworkException {
      debugPrint('[AuthRemoteDataSource] Backend offline, menggunakan Mock Fallback');
      return _mockLogin(login, password);
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthRemoteDataSource] Fallback Dev Mock Login');
      return _mockLogin(login, password);
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
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return AuthResponseModel(
        token: data['token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on NetworkException {
      return _mockRegisterUmb(name, email, phone, nim);
    } on AppException {
      rethrow;
    } catch (_) {
      return _mockRegisterUmb(name, email, phone, nim);
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
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return AuthResponseModel(
        token: data['token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on NetworkException {
      return _mockRegisterExternal(name, email, phone, institutionName);
    } on AppException {
      rethrow;
    } catch (_) {
      return _mockRegisterExternal(name, email, phone, institutionName);
    }
  }

  /// Mengambil profil pengguna aktif terkini
  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.me);
      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on NetworkException {
      return _mockDefaultUser();
    } on AppException {
      rethrow;
    } catch (_) {
      return _mockDefaultUser();
    }
  }

  /// Verifikasi kode 6 angka email
  Future<String> verifyEmailCode(String code) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmailCode,
        data: {'code': code.trim()},
      );
      return response.data?['message'] as String? ?? 'Email berhasil diverifikasi.';
    } on NetworkException {
      if (code == '123456' || code.length == 6) {
        return 'Email berhasil diverifikasi (Dev Mock).';
      }
      throw const ValidationException(
        message: 'Kode verifikasi tidak valid.',
        fieldErrors: {'code': ['Kode 6 digit yang Anda masukkan salah.']},
      );
    } on AppException {
      rethrow;
    } catch (_) {
      if (code == '123456' || code.length == 6) {
        return 'Email berhasil diverifikasi (Dev Mock).';
      }
      throw const ValidationException(
        message: 'Kode verifikasi tidak valid.',
        fieldErrors: {'code': ['Kode 6 digit yang Anda masukkan salah.']},
      );
    }
  }

  /// Kirim ulang kode verifikasi email
  Future<String> resendEmailCode() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.resendEmailCode,
      );
      return response.data?['message'] as String? ?? 'Kode verifikasi baru telah dikirimkan.';
    } catch (_) {
      return 'Kode verifikasi baru telah dikirimkan ke email Anda.';
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

  // === Dev Mock Generator (Kredensial Realistis Mahasiswa UMB) ===

  static UserModel _mockDefaultUser({bool suspended = false}) {
    return UserModel(
      id: 14,
      name: 'Yoga Gustira',
      email: 'yoga@mercubuana.ac.id',
      role: 'user',
      accountType: 'umb',
      nim: '41524010001',
      phone: '081234567890',
      avatarUrl: null,
      studyProgram: const StudyProgramModel(
        id: 1,
        code: '415',
        name: 'Teknik Informatika',
      ),
      cohortYear: 2024,
      emailVerified: true,
      isOrganizer: false,
      status: suspended ? 'suspended' : 'active',
      suspensionReason: suspended
          ? 'Akun Anda dinonaktifkan sementara karena pelanggaran tata tertib kepesertaan acara kampus.'
          : null,
    );
  }

  AuthResponseModel _mockLogin(String login, String password) {
    final cleaned = login.trim().toLowerCase();

    // Akun uji coba tersuspend
    if (cleaned == '41524010999' || cleaned == 'suspended@mercubuana.ac.id') {
      return AuthResponseModel(
        token: 'mock_token_suspended',
        user: _mockDefaultUser(suspended: true),
      );
    }

    // Login default realistis mahasiswa UMB
    if (cleaned == '41524010001' ||
        cleaned == 'yoga@mercubuana.ac.id' ||
        cleaned.contains('@') ||
        cleaned.length == 11) {
      final nimParse = NimParser.parse(cleaned);
      final programName = nimParse.programName ?? 'Teknik Informatika';
      final programCode = nimParse.programCode ?? '415';
      final cohortYear = nimParse.cohortYear ?? 2024;

      return AuthResponseModel(
        token: 'mock_sanctum_token_${DateTime.now().millisecondsSinceEpoch}',
        user: UserModel(
          id: 14,
          name: 'Yoga Gustira',
          email: cleaned.contains('@') ? cleaned : 'yoga@mercubuana.ac.id',
          role: 'user',
          accountType: 'umb',
          nim: nimParse.isValid ? nimParse.rawNim : '41524010001',
          phone: '081234567890',
          studyProgram: StudyProgramModel(
            id: 1,
            code: programCode,
            name: programName,
          ),
          cohortYear: cohortYear,
          emailVerified: true,
          isOrganizer: false,
          status: 'active',
        ),
      );
    }

    throw const ValidationException(
      message: 'Kredensial yang diberikan tidak cocok dengan data kami.',
      fieldErrors: {
        'login': ['Email atau NIM tidak terdaftar.'],
      },
    );
  }

  AuthResponseModel _mockRegisterUmb(String name, String email, String phone, String nim) {
    final nimParse = NimParser.parse(nim);
    return AuthResponseModel(
      token: 'mock_sanctum_token_${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 99,
        name: name,
        email: email,
        role: 'user',
        accountType: 'umb',
        nim: nim,
        phone: phone,
        studyProgram: StudyProgramModel(
          id: 1,
          code: nimParse.programCode ?? '415',
          name: nimParse.programName ?? 'Teknik Informatika',
        ),
        cohortYear: nimParse.cohortYear ?? 2024,
        emailVerified: false,
        isOrganizer: false,
        status: 'active',
      ),
    );
  }

  AuthResponseModel _mockRegisterExternal(String name, String email, String phone, String institutionName) {
    return AuthResponseModel(
      token: 'mock_sanctum_token_${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 100,
        name: name,
        email: email,
        role: 'user',
        accountType: 'external',
        phone: phone,
        institutionName: institutionName,
        emailVerified: false,
        isOrganizer: false,
        status: 'active',
      ),
    );
  }
}
