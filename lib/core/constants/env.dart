import 'package:flutter/foundation.dart';

/// Konfigurasi URL lingkungan TemuKampus.
/// Sesuai AGENTS.md & 02-MOBILE-ARCHITECTURE.md.
class AppEnv {
  AppEnv._();

  static const String _productionUrl = 'https://temukampus.mercubuana.ac.id/api/v1';
  static const String _localHostAndroid = 'http://10.0.2.2:8000/api/v1';
  static const String _localHostIos = 'http://localhost:8000/api/v1';
  static const String _localHostWeb = 'http://localhost:8000/api/v1';

  // Override kustom untuk uji coba di HP fisik via Wi-Fi LAN
  // Contoh: 'http://192.168.1.10:8000/api/v1'
  static String? customHostOverride;

  static String get baseUrl {
    if (customHostOverride != null && customHostOverride!.isNotEmpty) {
      return customHostOverride!;
    }

    if (kReleaseMode) {
      return _productionUrl;
    }

    if (kIsWeb) {
      return _localHostWeb;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _localHostAndroid;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return _localHostIos;
    }
  }
}

