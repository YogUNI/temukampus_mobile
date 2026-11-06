class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'TemuKampus';
  static const String appTagline = 'Temukan & Hadiri Acara Kampus UMB';

  // Secure Storage Keys
  static const String keyAccessToken = 'tk_access_token';
  static const String keyRefreshToken = 'tk_refresh_token';
  static const String keyUserData = 'tk_user_data';
  static const String keyRememberLogin = 'tk_remember_login';

  // Network Configuration
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);

  // File Upload Limits
  static const int maxUploadSizeBytes = 4 * 1024 * 1024; // 4 MB
  static const int targetCompressedSizeBytes = 2 * 1024 * 1024; // 2 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];

  // Domain Invariants
  static const int nimLength = 11;
  static const int uniqueCodeLength = 3;
}

