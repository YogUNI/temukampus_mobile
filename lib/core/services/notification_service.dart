import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Izin & notifikasi sistem (status bar HP).
///
/// Lapisan ini menangani dua hal yang diminta aplikasi produksi:
/// 1. **Meminta izin** `POST_NOTIFICATIONS` (Android 13+) / `UNUserNotificationCenter`
///    (iOS) sekali setelah pengguna masuk.
/// 2. **Menampilkan notifikasi sistem** saat aplikasi aktif/di background,
///    memakai `flutter_local_notifications`.
///
/// Push saat aplikasi ditutup total tetap butuh FCM (kredensial Firebase);
/// lihat catatan di `NotificationService.pushSupported`.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _permissionKey = 'tk_notification_permission';
  static const String _channelId = 'temukampus_activity';
  static const String _channelName = 'Aktivitas Temukampus';
  static const String _channelDescription =
      'Kabar pendaftaran, verifikasi pembayaran, dan acara kampusmu.';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Push dari server (FCM) belum aktif sampai kredensial Firebase dipasang.
  bool get pushSupported => false;

  /// Apakah platform ini mendukung notifikasi sistem.
  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (_initialized || !isSupported) return;

    try {
      await _initInternal();
    } catch (_) {
      // Plugin tidak tersedia (uji unit/desktop): nonaktifkan diam-diam.
      _initialized = false;
    }
  }

  Future<void> _initInternal() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Kanal Android wajib dibuat agar notifikasi punya prioritas & bunyi.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// Apakah pengguna pernah mengizinkan (disimpan lokal).
  Future<bool> hasPermission() async {
    if (!isSupported) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  /// Minta izin ke sistem. Mengembalikan `true` bila diizinkan.
  ///
  /// Android < 13 otomatis `true` (izin memang tidak diminta), iOS menampilkan
  /// dialog sistem, Android 13+ menampilkan dialog `POST_NOTIFICATIONS`.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    await init();

    bool granted = false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        granted = await android?.requestNotificationsPermission() ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        granted = await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (_) {
      granted = false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, granted);

    return granted;
  }

  /// Tandai izin sudah diberikan (dipakai saat FCM yang meminta izin).
  Future<void> markGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, true);
  }

  /// Simpan pilihan pengguna tanpa membuka dialog sistem (mis. tombol "Nanti").
  Future<void> rememberDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, false);
  }

  /// Tampilkan notifikasi di status bar.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported) return;
    if (!await hasPermission()) return;

    await init();

    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (_) {
      // Gagal menampilkan notifikasi sistem tidak boleh memutus alur aplikasi.
    }
  }
}
