/// Objek Failure untuk presentasi pesan galat di UI.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi gangguan pada server kampus. Silakan coba lagi.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Koneksi internet terputus. Pastikan perangkat Anda terhubung ke jaringan.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesi Anda telah berakhir, silakan masuk kembali.']);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;
  const ValidationFailure(super.message, [this.errors = const {}]);

  String? firstErrorFor(String field) {
    final list = errors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }
}

