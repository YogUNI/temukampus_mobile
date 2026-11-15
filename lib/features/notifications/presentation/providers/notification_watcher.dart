import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../data/repositories/notifications_repository.dart';
import 'notification_permission_provider.dart';
import 'notifications_badge_provider.dart';

/// Pengawas notifikasi selama aplikasi hidup.
///
/// Memeriksa notifikasi baru secara berkala; setiap notifikasi yang belum
/// pernah terlihat ditampilkan sebagai **notifikasi sistem** (status bar HP)
/// lewat [NotificationService]. Ini menutup celah "badge hanya terlihat kalau
/// layar notifikasi dibuka".
///
/// Catatan: push saat aplikasi **ditutup total** butuh FCM (kredensial
/// Firebase); pengawas ini bekerja saat aplikasi aktif atau di background
/// dengan proses masih hidup.
class NotificationWatcher {
  NotificationWatcher(this._ref);

  final Ref _ref;
  Timer? _timer;
  Timer? _bootTimer;

  /// ID notifikasi terbaru yang sudah pernah dilihat (in-memory per sesi).
  final Set<String> _seen = {};
  bool _primed = false;

  static const Duration _interval = Duration(seconds: 45);

  void start() {
    if (kIsWeb) return; // notifikasi sistem tidak dipakai di web
    _timer?.cancel();
    _bootTimer?.cancel();

    _timer = Timer.periodic(_interval, (_) => _tick());
    // Pemeriksaan pertama setelah layar beranda siap (disimpan agar bisa
    // dibatalkan — timer menggantung membuat widget test gagal).
    _bootTimer = Timer(const Duration(seconds: 8), _tick);
  }

  void stop() {
    _timer?.cancel();
    _bootTimer?.cancel();
    _timer = null;
    _bootTimer = null;
  }

  Future<void> _tick() async {
    final auth = _ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) return;

    final permission = _ref.read(notificationPermissionProvider);
    if (!permission.granted) return;

    try {
      final repository = _ref.read(notificationsRepositoryProvider);
      final result = await repository.getNotifications();

      // Badge ikut diperbarui agar lonceng tidak menunggu layar dibuka.
      _ref.invalidate(unreadNotificationsProvider);

      final fresh = result.items.where((n) => !n.isRead && !_seen.contains(n.id)).toList();

      // Putaran pertama hanya mencatat, tidak membanjiri layar dengan
      // notifikasi lama saat aplikasi baru dibuka.
      if (!_primed) {
        _seen.addAll(result.items.map((n) => n.id));
        _primed = true;
        return;
      }

      for (final notification in fresh.reversed) {
        _seen.add(notification.id);
        await NotificationService.instance.show(
          title: notification.title,
          body: notification.message,
          payload: notification.actionRoute,
        );
      }
    } catch (_) {
      // Diamkan: pengawas tidak boleh mengganggu alur utama.
    }
  }

  /// Dipanggil setelah pengguna menandai semua dibaca agar tidak muncul ulang.
  void markAllSeen(Iterable<String> ids) => _seen.addAll(ids);
}

final notificationWatcherProvider = Provider<NotificationWatcher>((ref) {
  final watcher = NotificationWatcher(ref);
  ref.onDispose(watcher.stop);
  watcher.start();
  return watcher;
});
