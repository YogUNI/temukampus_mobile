import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/push_service.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';

/// Sinkronisasi token perangkat dengan backend (`POST/DELETE /devices`).
///
/// Dipanggil otomatis: setiap pengguna masuk (dan setiap token FCM berubah),
/// serta saat keluar agar tidak ada push nyasar ke perangkat yang sudah
/// berganti akun.
final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  return PushRegistrar(ref.watch(apiClientProvider));
});

class PushRegistrar {
  PushRegistrar(
    this._apiClient, {
    Future<String?> Function()? tokenProvider,
  }) : _tokenProvider = tokenProvider ?? (() => PushService.instance.token());

  final ApiClient _apiClient;

  /// Sumber token perangkat (bisa diganti di tes tanpa Firebase).
  final Future<String?> Function() _tokenProvider;

  String? _lastToken;

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  /// Kirim token perangkat aktif ke server. Diam bila FCM belum siap.
  Future<void> registerCurrentDevice() async {
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) return;

    if (token == _lastToken) return;

    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/devices',
        data: {
          'token': token,
          'platform': _platform,
          'device_name': _platform == 'ios' ? 'iPhone' : 'Android',
        },
      );

      _lastToken = token;
    } on AppException {
      // Token akan dicoba lagi pada sinkronisasi berikutnya.
    } on DioException {
      // idem
    }
  }

  /// Hapus token saat pengguna keluar.
  Future<void> unregisterCurrentDevice() async {
    final token = _lastToken ?? await _tokenProvider();
    if (token == null || token.isEmpty) return;

    try {
      await _apiClient.delete<Map<String, dynamic>>(
        '/devices',
        data: {'token': token},
      );
      _lastToken = null;
    } on AppException {
      // Diamkan: logout tetap berjalan.
    } on DioException {
      // idem
    }
  }
}

/// Menyambungkan status login dengan pendaftaran token perangkat.
final pushSyncProvider = Provider<void>((ref) {
  final registrar = ref.watch(pushRegistrarProvider);

  ref.listen(authNotifierProvider, (previous, next) {
    if (next.isAuthenticated) {
      registrar.registerCurrentDevice();
    } else if (previous?.isAuthenticated == true) {
      registrar.unregisterCurrentDevice();
    }
  });

  // Token bisa berubah kapan saja (reinstall, pemulihan aplikasi).
  PushService.instance.onTokenRefresh((_) {
    if (ref.read(authNotifierProvider).isAuthenticated) {
      registrar.registerCurrentDevice();
    }
  });
});
