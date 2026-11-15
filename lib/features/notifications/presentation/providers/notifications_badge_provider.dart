import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository.dart';

/// Jumlah notifikasi belum dibaca untuk badge lonceng di beranda.
///
/// Dipisah dari daftar notifikasi supaya beranda tidak perlu memuat seluruh
/// isi notifikasi hanya untuk menampilkan angka.
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getUnreadCount();
});
