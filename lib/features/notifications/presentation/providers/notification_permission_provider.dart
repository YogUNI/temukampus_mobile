import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_service.dart';

/// Status izin notifikasi sistem.
///
/// `false` bisa berarti "belum pernah ditanya" atau "ditolak" — dibedakan
/// lewat [NotificationPermissionState.asked] agar aplikasi hanya menampilkan
/// dialog permintaan sekali (seperti aplikasi produksi pada umumnya).
class NotificationPermissionState {
  final bool granted;
  final bool asked;

  const NotificationPermissionState({this.granted = false, this.asked = false});

  NotificationPermissionState copyWith({bool? granted, bool? asked}) {
    return NotificationPermissionState(
      granted: granted ?? this.granted,
      asked: asked ?? this.asked,
    );
  }
}

final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, NotificationPermissionState>((ref) {
  return NotificationPermissionNotifier();
});

class NotificationPermissionNotifier extends StateNotifier<NotificationPermissionState> {
  static const String _askedKey = 'tk_notification_asked';

  NotificationPermissionNotifier() : super(const NotificationPermissionState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = await NotificationService.instance.hasPermission();

    state = NotificationPermissionState(
      granted: granted,
      asked: prefs.getBool(_askedKey) ?? false,
    );
  }

  /// Tampilkan dialog izin sistem (Android 13+ / iOS).
  ///
  /// FCM meminta izin yang sama dengan notifikasi lokal; bila Firebase belum
  /// aktif (mis. web/desktop), fallback ke `NotificationService`.
  Future<bool> request() async {
    bool granted = false;

    if (PushService.instance.isReady) {
      granted = await PushService.instance.requestPermission();
      if (granted) {
        await NotificationService.instance.markGranted();
      }
    }

    if (!granted) {
      granted = await NotificationService.instance.requestPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);

    state = NotificationPermissionState(granted: granted, asked: true);
    return granted;
  }

  /// Pengguna memilih "Nanti" — jangan tanya lagi otomatis.
  Future<void> decline() async {
    await NotificationService.instance.rememberDeclined();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);

    state = state.copyWith(granted: false, asked: true);
  }
}
