import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor Dio untuk menyuntikkan Sanctum Bearer Token
/// dan menangani sesi kedaluwarsa (HTTP 401 Unauthenticated).
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final void Function()? _onSessionExpired;

  AuthInterceptor(this._storage, [this._onSessionExpired]);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Hapus token lokal karena sudah tidak valid di database backend
      _storage.clearAll();
      _onSessionExpired?.call();
    }
    return handler.next(err);
  }
}

