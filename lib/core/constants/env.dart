import 'package:flutter/foundation.dart';

/// Konfigurasi URL lingkungan TemuKampus.
/// Sesuai AGENTS.md & 02-MOBILE-ARCHITECTURE.md.
class AppEnv {
  AppEnv._();

  static const String _productionUrl = 'https://temukampus.mercubuana.ac.id/api/v1';

  /// Backend lokal Laragon (Apache, virtual host) — dipakai web/desktop/iOS.
  static const String _localLaragonUrl = 'http://temukampus.test/api/v1';

  /// Emulator Android memetakan host ke 10.0.2.2. Apache Laragon tidak bisa
  /// dipanggil lewat IP ini karena virtual host dicocokkan dari header Host,
  /// jadi jalur yang didukung adalah `php artisan serve --host=0.0.0.0`.
  static const String _localAndroidUrl = 'http://10.0.2.2:8000/api/v1';

  /// Override saat build: `flutter run --dart-define=API_BASE_URL=http://192.168.1.10/api/v1`
  static const String _defineBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Override kustom saat runtime (uji coba di HP fisik via Wi-Fi LAN).
  static String? customHostOverride;

  /// Apakah halaman web sedang disajikan dari mesin pengembang.
  ///
  /// `flutter build web` menghasilkan build release, dan sebelumnya build
  /// release selalu memakai URL produksi — akibatnya build web yang dibuka di
  /// localhost menembak host produksi yang belum ada dan katalog gagal dimuat.
  /// Sekarang host yang menentukan: localhost/IP lokal memakai backend Laragon.
  static bool get _isLocalWebHost {
    if (!kIsWeb) return false;

    final host = Uri.base.host;

    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
      return true;
    }

    // 192.168.x.x / 10.x.x.x / 172.16-31.x.x → jaringan lokal (HP fisik via Wi-Fi).
    final isPrivateIpv4 = RegExp(r'^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(host);

    return isPrivateIpv4 || host == 'temukampus.test';
  }

  static String get baseUrl {
    if (customHostOverride != null && customHostOverride!.isNotEmpty) {
      return customHostOverride!;
    }

    if (_defineBaseUrl.isNotEmpty) {
      return _defineBaseUrl;
    }

    if (kIsWeb) {
      return _isLocalWebHost ? _localLaragonUrl : _productionUrl;
    }

    if (kReleaseMode) {
      return _productionUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _localAndroidUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return _localLaragonUrl;
    }
  }
}

