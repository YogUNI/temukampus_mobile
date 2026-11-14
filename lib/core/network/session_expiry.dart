/// Titik sambung antara lapisan jaringan dan pengelola sesi.
///
/// `AuthInterceptor` perlu memberi tahu lapisan auth bahwa token sudah tidak
/// berlaku (HTTP 401). Kalau `api_client.dart` mengimpor `auth_notifier`
/// langsung, provider saling bergantung (dio → auth → repository → datasource →
/// apiClient → dio) dan analyzer menolak siklusnya. Lewat holder kecil ini
/// ketergantungan tetap satu arah: fitur auth mendaftarkan callback, jaringan
/// hanya memanggilnya.
class SessionExpiry {
  SessionExpiry._();

  static void Function()? _callback;

  /// Dipanggil sekali oleh lapisan aplikasi saat widget root dibangun.
  static void register(void Function() callback) {
    _callback = callback;
  }

  /// Dipanggil interceptor setelah token lokal dibersihkan.
  static void notify() {
    _callback?.call();
  }
}
