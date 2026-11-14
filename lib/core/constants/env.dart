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

  static String get baseUrl {
    if (customHostOverride != null && customHostOverride!.isNotEmpty) {
      return customHostOverride!;
    }

    if (_defineBaseUrl.isNotEmpty) {
      return _defineBaseUrl;
    }

    if (kReleaseMode) {
      return _productionUrl;
    }

    if (kIsWeb) {
      return _localLaragonUrl;
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

