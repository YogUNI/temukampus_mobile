# TemuKampus Mobile — Technical Architecture & Implementation Spec

Dokumen ini adalah spesifikasi arsitektur teknis untuk pengembang dan AI coding assistant yang bekerja pada basis kode **TemuKampus Mobile (Flutter)**.

---

## 1. Arsitektur Proyek (Feature-First Clean Architecture)

Struktur kode mengadopsi pendekatan **Feature-First**: setiap fitur memiliki domain, data, dan presentation layer sendiri. Ini memastikan kode modular, mudah diuji, dan tidak terjadi spaghetti dependency.

```
lib/
├── app/
│   ├── app.dart                       # Root MaterialApp widget & global providers
│   ├── router/
│   │   ├── app_router.dart            # GoRouter definition & redirect guards
│   │   └── route_names.dart           # Constants nama rute ('/login', '/events/:slug', dll)
│   └── theme/
│       ├── app_colors.dart            # Design tokens warna (Cobalt, Signal, Ink, Paper, dll)
│       ├── app_typography.dart        # Plus Jakarta Sans & Bricolage Grotesque
│       ├── app_theme.dart             # ThemeData (Light Mode primary, Dark ready)
│       └── components/                # Komponen kustom global (TicketCard, StatusPill, Button)
│
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart         # Path URL backend ('/events', '/auth/login', dll)
│   │   ├── app_constants.dart         # Storage keys, app limits (max upload 4MB)
│   │   └── env.dart                   # Base URL konfigurasi lingkungan
│   ├── errors/
│   │   ├── exceptions.dart            # ServerException, NetworkException, AuthException
│   │   └── failures.dart              # Failure objects untuk presentasi UI
│   ├── network/
│   │   ├── api_client.dart            # Dio wrapper instance
│   │   ├── auth_interceptor.dart      # Inject Bearer token & handle 401 unauthenticated
│   │   ├── error_interceptor.dart     # Parse Laravel 422 JSON validation errors
│   │   └── logging_interceptor.dart   # Pretty curl logging di mode debug
│   ├── storage/
│   │   ├── secure_storage_service.dart # flutter_secure_storage (Token auth, refresh token)
│   │   └── local_cache_service.dart   # SharedPreferences/Hive (User profile, cached catalog)
│   └── utils/
│       ├── formatters.dart            # Rupiah formatter (Rp 25.137), Carbon Date ID
│       ├── nim_parser.dart            # Client-side 11-digit NIM parser
│       └── image_compressor.dart      # Compressing proof photos to <= 2 MB before upload
│
├── features/
│   ├── auth/
│   │   ├── data/ (models, datasources, repositories)
│   │   ├── domain/ (entities, usecases)
│   │   └── presentation/ (controllers/notifiers, screens: login, register, forgot_password)
│   ├── events/
│   │   ├── data/ (event_model, event_repository)
│   │   ├── domain/ (event_entity, category_entity)
│   │   └── presentation/ (catalog_screen, event_detail_screen, widgets: event_card, filter_chips)
│   ├── registration/
│   │   ├── data/ (registration_model, registration_repository)
│   │   └── presentation/ (register_form_screen, payment_instructions_widget, upload_proof_sheet)
│   ├── tickets/
│   │   ├── data/ (ticket_model, ticket_repository)
│   │   └── presentation/ (my_tickets_screen, ticket_detail_screen, qr_code_widget)
│   ├── scanner/ (Khusus Panitia)
│   │   ├── data/ (checkin_repository)
│   │   └── presentation/ (scanner_screen, checkin_result_modal, manual_nim_lookup_sheet)
│   └── profile/
│       ├── data/ (user_model, profile_repository)
│       └── presentation/ (profile_screen, edit_profile_screen, change_password_screen)
│
└── main.dart                          # App entry point
```

---

## 2. Dependensi Kunci (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management & Dependency Injection
  flutter_riverpod: ^2.5.1

  # Routing
  go_router: ^14.2.0

  # Networking & Serialization
  dio: ^5.5.0+1
  json_annotation: ^4.9.0
  freezed_annotation: ^2.4.1

  # Local Storage & Security
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.3

  # Fonts & UI Utilities
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  intl: ^0.19.0

  # Hardware: Camera, Image Picker & Scanner
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0
  mobile_scanner: ^5.1.1
  qr_flutter: ^4.1.0

  # Interaction & Device Feedback
  flutter_vibrate: ^1.3.0
  url_launcher: ^6.3.0
  share_plus: ^9.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

---

## 3. Strategi Jaringan & Dio Client (`ApiClient`)

### 3.1 Base URL & Environment Config
Konfigurasi Base URL disesuaikan dengan target device:

```dart
// lib/core/constants/env.dart
class AppEnv {
  static const String _localHostAndroid = 'http://10.0.2.2:8000/api/v1';
  static const String _localHostIos = 'http://localhost:8000/api/v1';
  static const String _productionUrl = 'https://temukampus.mercubuana.ac.id/api/v1';

  static String get baseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _productionUrl;
    }
    // Ganti dengan IP LAN laptop jika menguji di HP fisik via Wi-Fi
    return defaultTargetPlatform == TargetPlatform.android
        ? _localHostAndroid
        : _localHostIos;
  }
}
```

### 3.2 Auth Interceptor (Bearer Token & 401 Auto Logout)
```dart
// lib/core/network/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Function() _onSessionExpired;

  AuthInterceptor(this._storage, this._onSessionExpired);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Hapus token dan lempar sinyal sesi berakhir
      _storage.clearTokens();
      _onSessionExpired();
    }
    return handler.next(err);
  }
}
```

### 3.3 Penanganan Galat Validasi Laravel (HTTP 422)
Laravel 13 mengembalikan format galat standar:
```json
{
  "message": "Data yang diberikan tidak valid.",
  "errors": {
    "nim": ["NIM harus terdiri dari 11 digit angka."],
    "payment_proof": ["Ukuran bukti transfer tidak boleh lebih dari 4096 kilobita."]
  }
}
```
`ErrorInterceptor` harus mengekstrak peta `Map<String, List<String>>` dari `errors` agar form di Flutter bisa langsung menandai field input yang salah dengan teks merah yang tepat.

---

## 4. Keamanan & Manajemen Token (Laravel Sanctum)

1. **Penyimpanan Kredensial:**
   - Token otentikasi disimpan menggunakan `flutter_secure_storage` (Keystore di Android dan Keychain di iOS).
   - Jangan pernah menyimpan token di `SharedPreferences` biasa karena plain text.
2. **Kamera & Izin File:**
   - Izin `android.permission.CAMERA` dan `android.permission.READ_MEDIA_IMAGES` diminta hanya ketika pengguna menekan tombol "Unggah Bukti" atau membuka menu "Scanner".
3. **Privasi Gambar Bukti Pembayaran:**
   - Bukti bayar yang diunggah ke server Laravel berada di disk `private` (`storage/app/private/proofs/`).
   - Mobile app mengakses gambar bukti hanya melalui endpoint resmi berautentikasi: `GET /api/v1/tickets/{code}/proof` dengan header `Authorization: Bearer <token>`.

---

## 5. Algoritma Klien Kritis

### 5.1 Parser NIM Klien (`NimParser`)
Mahasiswa UMB memiliki format NIM 11 digit:
- **Digit 1–3:** Kode Program Studi (e.g. `415` -> Teknik Informatika, `418` -> Sistem Informasi, `414` -> Teknik Sipil).
- **Digit 4–5:** Angkatan Mahasiswa (`20` + dua digit, e.g. `24` -> 2024).
- **Digit 6–11:** Nomor urut unik.

```dart
// lib/core/utils/nim_parser.dart
class NimResult {
  final bool isValid;
  final String? programCode;
  final int? cohortYear;
  final String? errorMessage;

  NimResult({required this.isValid, this.programCode, this.cohortYear, this.errorMessage});
}

class NimParser {
  static NimResult parse(String rawNim) {
    final cleaned = rawNim.trim();
    if (cleaned.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return NimResult(
        isValid: false,
        errorMessage: 'NIM harus terdiri dari 11 digit angka.',
      );
    }

    final code = cleaned.substring(0, 3);
    final yearSuffix = cleaned.substring(3, 5);
    final year = 2000 + int.parse(yearSuffix);

    return NimResult(
      isValid: true,
      programCode: code,
      cohortYear: year,
    );
  }
}
```

### 5.2 Kompresi Gambar Bukti Bayar
Sebelum file dikirim ke server, kompres gambar di latar belakang agar menghemat kuota mahasiswa dan mempercepat upload:
```dart
// lib/core/utils/image_compressor.dart
class ImageCompressor {
  static Future<File?> compress(File originalFile) async {
    final targetPath = '${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1080,
      minHeight: 1920,
    );
    return result != null ? File(result.path) : null;
  }
}
```

---

## 6. Offline-First Caching untuk Tiket
Agar mahasiswa tetap bisa menunjukkan tiket di meja registrasi kampus meski sinyal internet di basement/aula lemah:
1. Saat halaman `/my-tickets` dibuka, simpan daftar tiket aktif (beserta string `ticket_code` dan data acara) ke cache lokal (`Hive` atau `SharedPreferences`).
2. Generator QR (`qr_flutter`) berjalan **secara lokal di HP** menggunakan string `ticket_code` (e.g., `TK-7F3KQ9`). QR Code tidak diunduh sebagai gambar dari internet, melainkan digambar langsung oleh engine vektor Flutter. Mahasiswa dijamin 100% bisa membuka QR code tiket walau sedang *Airplane Mode*!

