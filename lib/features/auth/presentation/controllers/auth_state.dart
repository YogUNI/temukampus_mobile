import '../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  needsEmailVerification,
  suspended,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final Map<String, List<String>> validationErrors;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.validationErrors = const {},
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.authenticating() => const AuthState(status: AuthStatus.authenticating);

  factory AuthState.authenticated(UserModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  factory AuthState.needsEmailVerification(UserModel user) => AuthState(
        status: AuthStatus.needsEmailVerification,
        user: user,
      );

  factory AuthState.suspended(UserModel user, String reason) => AuthState(
        status: AuthStatus.suspended,
        user: user,
        errorMessage: reason,
      );

  factory AuthState.error(String message, [Map<String, List<String>> errors = const {}]) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
        validationErrors: errors,
      );

  /// Sesi berakhir (HTTP 401): token lokal sudah dihapus interceptor, pengguna
  /// dikembalikan ke halaman masuk dengan pesan yang jelas (AGENTS.md §Code
  /// Quality #4). Status sengaja `unauthenticated` agar router me-redirect ke
  /// `/login` dari rute mana pun yang butuh sesi.
  factory AuthState.sessionExpired() => const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Sesi Anda telah berakhir, silakan masuk kembali.',
      );

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isSuspended => status == AuthStatus.suspended;

  String? firstErrorFor(String field) {
    final list = validationErrors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }
}
