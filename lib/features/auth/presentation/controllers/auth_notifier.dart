import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  /// Memeriksa status token tersimpan di SecureStorage saat aplikasi dibuka
  Future<void> checkAuthStatus() async {
    state = AuthState.authenticating();
    try {
      final hasToken = await _repository.hasValidToken();
      if (!hasToken) {
        state = AuthState.unauthenticated();
        return;
      }

      try {
        final user = await _repository.syncCurrentUser();
        _handleUserState(user);
      } catch (_) {
        final cached = await _repository.getCachedUser();
        if (cached != null) {
          _handleUserState(cached);
        } else {
          state = AuthState.unauthenticated();
        }
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  /// Masuk dengan NIM atau Email
  Future<bool> login({
    required String login,
    required String password,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.login(login: login, password: password);
      _handleUserState(user);
      return state.status != AuthStatus.suspended && state.status != AuthStatus.error;
    } on SuspendedAccountException catch (e) {
      // Akun ditangguhkan: tampilkan dialog pemblokiran dengan alasan admin.
      final json = e.userJson;
      final user = json != null ? UserModel.fromJson(json) : _placeholderUser(login);

      state = AuthState.suspended(user, e.message);
      return false;
    } on ValidationException catch (e) {
      state = AuthState.error(e.message, e.fieldErrors);
      return false;
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (_) {
      state = AuthState.error('Gagal masuk. Periksa jaringan internet Anda.');
      return false;
    }
  }

  /// Registrasi Mahasiswa UMB (Validasi 11 Digit NIM)
  Future<bool> registerUmb({
    required String name,
    required String email,
    required String phone,
    required String nim,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.registerUmb(
        name: name,
        email: email,
        phone: phone,
        nim: nim,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = AuthState.needsEmailVerification(user);
      return true;
    } on ValidationException catch (e) {
      state = AuthState.error(e.message, e.fieldErrors);
      return false;
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (_) {
      state = AuthState.error('Gagal mendaftar. Silakan coba lagi.');
      return false;
    }
  }

  /// Registrasi Peserta Eksternal
  Future<bool> registerExternal({
    required String name,
    required String email,
    required String phone,
    required String institutionName,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.registerExternal(
        name: name,
        email: email,
        phone: phone,
        institutionName: institutionName,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = AuthState.needsEmailVerification(user);
      return true;
    } on ValidationException catch (e) {
      state = AuthState.error(e.message, e.fieldErrors);
      return false;
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (_) {
      state = AuthState.error('Gagal mendaftar. Silakan coba lagi.');
      return false;
    }
  }

  /// Verifikasi kode 6 angka email
  Future<bool> verifyEmail(String code) async {
    try {
      await _repository.verifyEmailCode(code);
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(emailVerified: true);
        state = AuthState.authenticated(updatedUser);
      }
      return true;
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (_) {
      state = AuthState.error('Kode verifikasi tidak valid atau telah kedaluwarsa.');
      return false;
    }
  }

  /// Kirim ulang kode verifikasi
  Future<String?> resendEmailCode() async {
    try {
      return await _repository.resendEmailCode();
    } catch (_) {
      return null;
    }
  }

  /// Minta kode reset kata sandi. `null` = berhasil dikirim.
  Future<String?> requestPasswordReset(String email) async {
    try {
      await _repository.forgotPassword(email);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal mengirim kode. Periksa koneksi lalu coba lagi.';
    }
  }

  /// Reset kata sandi memakai kode 6 angka. `null` = berhasil.
  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await _repository.resetPassword(
        email: email,
        code: code,
        password: newPassword,
        passwordConfirmation: confirmation,
      );
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal mengganti kata sandi. Periksa koneksi lalu coba lagi.';
    }
  }

  /// Perbarui nama / nomor WhatsApp / asal institusi.
  ///
  /// Mengembalikan `null` bila berhasil, atau pesan galat siap tampil.
  Future<String?> updateProfile({
    required String name,
    String? phone,
    String? institutionName,
  }) async {
    try {
      final user = await _repository.updateProfile(
        name: name,
        phone: phone,
        institutionName: institutionName,
      );
      state = AuthState.authenticated(user);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal menyimpan perubahan. Periksa koneksi lalu coba lagi.';
    }
  }

  /// Ganti kata sandi. `null` = berhasil.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        password: newPassword,
        passwordConfirmation: confirmation,
      );
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal mengganti kata sandi. Periksa koneksi lalu coba lagi.';
    }
  }

  /// Unggah foto profil. `null` = berhasil.
  Future<String?> updateAvatar(PickedImageData image) async {
    try {
      final user = await _repository.uploadAvatar(image);
      state = AuthState.authenticated(user);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.';
    }
  }

  /// Hapus foto profil. `null` = berhasil.
  Future<String?> removeAvatar() async {
    try {
      final user = await _repository.removeAvatar();
      state = AuthState.authenticated(user);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal menghapus foto. Periksa koneksi lalu coba lagi.';
    }
  }

  /// Keluar akun (Logout)
  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  /// Dipanggil interceptor Dio saat backend menjawab HTTP 401.
  ///
  /// Token lokal sudah dihapus oleh interceptor; di sini cukup mengubah state
  /// agar router memindahkan pengguna ke `/login` dengan pesan sesi berakhir.
  void handleSessionExpired() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = AuthState.sessionExpired();
  }

  void _handleUserState(user) {
    if (user.isSuspended) {
      state = AuthState.suspended(
        user,
        user.suspensionReason ??
            'Akun Anda dinonaktifkan sementara oleh admin kampus. Hubungi BAAK untuk informasi lebih lanjut.',
      );
    } else if (!user.emailVerified) {
      state = AuthState.needsEmailVerification(user);
    } else {
      state = AuthState.authenticated(user);
    }
  }

  /// Pengguna sementara saat backend menolak login tanpa menyertakan data
  /// pengguna (dipakai hanya untuk menampilkan dialog pemblokiran).
  UserModel _placeholderUser(String login) => UserModel(
        id: 0,
        name: login,
        email: login.contains('@') ? login : '',
        status: 'suspended',
      );
}
