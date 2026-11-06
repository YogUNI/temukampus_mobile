/// Kumpulan Exception tingkat data/network di TemuKampus Mobile.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'Terjadi kesalahan pada server kampus.', super.statusCode]);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Koneksi internet terputus. Silakan periksa jaringan Anda.']);
}

class AuthException extends AppException {
  final String? errorCode;
  const AuthException([super.message = 'Sesi Anda telah berakhir, silakan masuk kembali.', this.errorCode, super.statusCode = 401]);
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  const ValidationException({
    String message = 'Data yang dikirimkan tidak valid.',
    this.fieldErrors = const {},
  }) : super(message, 422);

  /// Mengambil pesan error pertama dari field tertentu
  String? firstErrorFor(String field) {
    final errors = fieldErrors[field];
    if (errors != null && errors.isNotEmpty) {
      return errors.first;
    }
    return null;
  }
}
