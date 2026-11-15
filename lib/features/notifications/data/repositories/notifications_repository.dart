import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../models/app_notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(notificationsRemoteDataSourceProvider));
});

class NotificationsRepository {
  final NotificationsRemoteDataSource _remote;

  NotificationsRepository(this._remote);

  Future<({List<AppNotificationModel> items, int unreadCount})> getNotifications({
    String filter = 'all',
  }) {
    return _remote.getNotifications(filter: filter);
  }

  Future<int> getUnreadCount() => _remote.getUnreadCount();

  Future<int> markRead(String id) => _remote.markRead(id);

  Future<int> markAllRead() => _remote.markAllRead();

  Future<int> delete(String id) => _remote.delete(id);
}

/// Status daftar notifikasi untuk layar.
class NotificationsState {
  final bool isLoading;
  final String? errorMessage;
  final List<AppNotificationModel> items;
  final int unreadCount;
  final String filter; // all | unread

  const NotificationsState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.unreadCount = 0,
    this.filter = 'all',
  });

  bool get isEmpty => !isLoading && errorMessage == null && items.isEmpty;
  bool get hasUnread => unreadCount > 0;

  NotificationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AppNotificationModel>? items,
    int? unreadCount,
    String? filter,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      filter: filter ?? this.filter,
    );
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref.watch(notificationsRepositoryProvider));
});

class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsController(this._repository) : super(const NotificationsState());

  Future<void> load({String? filter}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, filter: filter);

    try {
      final result = await _repository.getNotifications(filter: filter ?? state.filter);
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        unreadCount: result.unreadCount,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat notifikasi. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  /// Muat ulang tanpa mengosongkan layar (pull-to-refresh).
  Future<void> refresh() => load();

  void setFilter(String filter) {
    if (state.filter == filter) return;
    load(filter: filter);
  }

  Future<void> markRead(AppNotificationModel item) async {
    if (item.isRead) return;

    // Optimistis: UI langsung berubah, server menyusul.
    final updated = state.items
        .map((e) => e.id == item.id ? e.copyWith(isRead: true) : e)
        .toList();

    state = state.copyWith(
      items: updated,
      unreadCount: (state.unreadCount - 1).clamp(0, 999),
    );

    try {
      final unread = await _repository.markRead(item.id);
      state = state.copyWith(unreadCount: unread);
    } catch (_) {
      // Gagal di server: kembalikan status baca agar tidak menipu pengguna.
      state = state.copyWith(
        items: state.items
            .map((e) => e.id == item.id ? e.copyWith(isRead: false) : e)
            .toList(),
        unreadCount: state.unreadCount + 1,
      );
    }
  }

  Future<void> markAllRead() async {
    final previous = state.items;

    state = state.copyWith(
      items: previous.map((e) => e.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );

    try {
      await _repository.markAllRead();
    } catch (_) {
      state = state.copyWith(items: previous);
      await load();
    }
  }

  Future<void> delete(AppNotificationModel item) async {
    final previous = state.items;
    state = state.copyWith(
      items: previous.where((e) => e.id != item.id).toList(),
      unreadCount: item.isRead ? state.unreadCount : (state.unreadCount - 1).clamp(0, 999),
    );

    try {
      final unread = await _repository.delete(item.id);
      state = state.copyWith(unreadCount: unread);
    } catch (_) {
      state = state.copyWith(items: previous);
    }
  }
}
