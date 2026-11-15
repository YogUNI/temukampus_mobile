import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/app_notification_model.dart';

final notificationsRemoteDataSourceProvider = Provider<NotificationsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRemoteDataSource(apiClient);
});

/// Sumber data notifikasi in-app (tabel `notifications` backend).
class NotificationsRemoteDataSource {
  final ApiClient _apiClient;

  NotificationsRemoteDataSource(this._apiClient);

  /// Daftar notifikasi + jumlah belum dibaca.
  Future<({List<AppNotificationModel> items, int unreadCount})> getNotifications({
    String filter = 'all',
    int perPage = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'filter': filter, 'per_page': perPage},
      );

      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      final items = rawList
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return (
        items: items,
        unreadCount: (response.data?['unread_count'] as int?) ?? 0,
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Jumlah notifikasi belum dibaca (untuk badge lonceng).
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );

      final data = response.data?['data'];
      return data is Map<String, dynamic> ? (data['count'] as int? ?? 0) : 0;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Tandai satu notifikasi sudah dibaca.
  Future<int> markRead(String id) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications/$id/read',
      );

      final data = response.data?['data'];
      return data is Map<String, dynamic> ? (data['unread_count'] as int? ?? 0) : 0;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Tandai semua notifikasi sudah dibaca.
  Future<int> markAllRead() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications/read-all',
      );

      final data = response.data?['data'];
      return data is Map<String, dynamic> ? (data['unread_count'] as int? ?? 0) : 0;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Hapus satu notifikasi.
  Future<int> delete(String id) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/notifications/$id',
      );

      final data = response.data?['data'];
      return data is Map<String, dynamic> ? (data['unread_count'] as int? ?? 0) : 0;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  AppException _asAppException(DioException e) {
    final error = e.error;
    if (error is AppException) return error;

    return ServerException(
      'Tidak dapat menghubungi server TemuKampus. Periksa koneksi lalu coba lagi.',
      e.response?.statusCode,
    );
  }
}
