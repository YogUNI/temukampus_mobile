import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Penangan pesan FCM saat aplikasi **tidak aktif** (background/tertutup).
///
/// Harus fungsi top-level dan tidak boleh memakai UI. Notifikasi dengan payload
/// `notification` sudah ditampilkan otomatis oleh sistem, jadi di sini cukup
/// menyiapkan Firebase agar pesan data tidak error.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Konfigurasi Firebase tidak tersedia: abaikan.
  }
}

/// Push notification (FCM) untuk aplikasi TemuKampus.
///
/// Backend mengirim lewat FCM HTTP v1; perangkat menerima:
/// - **foreground**: ditampilkan sendiri lewat [NotificationService]
/// - **background/tertutup**: sistem Android/iOS menampilkan otomatis
///
/// Token perangkat dikirim ke `POST /devices` agar server tahu ke mana push
/// harus diarahkan (lihat `PushRegistrar`).
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  bool _initialized = false;

  /// Apakah FCM siap dipakai di perangkat ini.
  bool get isReady => _initialized;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      await Firebase.initializeApp();

      // Izin notifikasi: Android 13+ & iOS memakai dialog sistem yang sama
      // dengan NotificationService, jadi cukup diminta sekali dari sana.
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      // Pesan masuk saat aplikasi dibuka → tampilkan di status bar.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? message.data['title']?.toString();
        final body = message.notification?.body ?? message.data['message']?.toString();

        if (title == null && body == null) return;

        NotificationService.instance.show(
          title: title ?? 'TemuKampus',
          body: body ?? '',
          payload: message.data['route']?.toString(),
        );
      });

      _initialized = true;
    } catch (_) {
      // Tanpa google-services.json / konfigurasi iOS, aplikasi tetap jalan
      // dengan notifikasi in-app (lonceng) saja.
      _initialized = false;
    }
  }

  /// Minta izin notifikasi ke sistem (iOS wajib; Android 13+ juga).
  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Ambil registration token FCM perangkat.
  ///
  /// `getToken()` ditandai deprecated di firebase_messaging 17 (pengarang
  /// menyarankan Firebase Installation ID lewat `register()`/`onRegistered`),
  /// tetapi backend kita mengirim lewat FCM HTTP v1 `message.token` yang
  /// memang menerima **registration token** ini. Beralih ke FID berarti
  /// mengubah kontrak server dan belum bisa diuji di perangkat pada sesi ini,
  /// jadi jalur yang terbukti dipakai lebih dulu.
  Future<String?> token() async {
    if (!_initialized) return null;

    try {
      if (Platform.isIOS) {
        // APNs token harus siap sebelum FCM memberi token di iOS.
        await FirebaseMessaging.instance.getAPNSToken();
      }

      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Dipanggil setiap FCM memperbarui token.
  void onTokenRefresh(void Function(String token) callback) {
    if (!_initialized) return;

    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(callback);
  }

  /// Rute tujuan saat pengguna mengetuk notifikasi (aplikasi dibuka dari tray).
  void onNotificationTap(void Function(String route) callback) {
    if (!_initialized) return;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route']?.toString();
      if (route != null && route.startsWith('/')) callback(route);
    });
  }

  /// Payload notifikasi yang membuka aplikasi dari keadaan tertutup.
  Future<String?> initialRoute() async {
    if (!_initialized) return null;

    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      final route = message?.data['route']?.toString();

      return route != null && route.startsWith('/') ? route : null;
    } catch (_) {
      return null;
    }
  }
}
