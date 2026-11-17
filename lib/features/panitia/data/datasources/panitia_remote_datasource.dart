import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/panitia_models.dart';

final panitiaRemoteDataSourceProvider = Provider<PanitiaRemoteDataSource>((ref) {
  return PanitiaRemoteDataSource(ref.watch(apiClientProvider));
});

/// Semua panggilan panel panitia. Aksi (setujui/revisi/tolak/presensi)
/// dijalankan backend memakai action yang sama dengan panel web, jadi aplikasi
/// tidak pernah punya aturan sendiri.
class PanitiaRemoteDataSource {
  final ApiClient _apiClient;

  PanitiaRemoteDataSource(this._apiClient);

  Future<PanitiaDashboardModel> dashboard() async {
    final response = await _call(
      () => _apiClient.get<Map<String, dynamic>>(ApiEndpoints.panitiaDashboard),
    );

    return PanitiaDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<RegistrantPageModel> registrants(
    int eventId, {
    String tab = 'menunggu',
    String? search,
  }) async {
    final response = await _call(
      () => _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.panitiaRegistrations(eventId),
        queryParameters: {
          'tab': tab,
          if (search != null && search.isNotEmpty) 'q': search,
        },
      ),
    );

    return RegistrantPageModel.fromJson(response.data ?? {});
  }

  /// Aksi tunggal pada satu pendaftaran.
  Future<String> act({
    required int registrationId,
    required String action,
    String? reviewNote,
  }) async {
    final path = switch (action) {
      'approve' => ApiEndpoints.panitiaApprove(registrationId),
      'revise' => ApiEndpoints.panitiaRevise(registrationId),
      'reject' => ApiEndpoints.panitiaReject(registrationId),
      'check-in' => ApiEndpoints.panitiaCheckIn(registrationId),
      _ => throw ArgumentError('Aksi tidak dikenal: $action'),
    };

    final response = await _call(
      () => _apiClient.post<Map<String, dynamic>>(
        path,
        data: reviewNote == null ? null : {'review_note': reviewNote},
      ),
    );

    return response.data?['message'] as String? ?? 'Berhasil.';
  }

  Future<String> cancelCheckIn(int registrationId) async {
    final response = await _call(
      () => _apiClient.delete<Map<String, dynamic>>(
        ApiEndpoints.panitiaCheckIn(registrationId),
      ),
    );

    return response.data?['message'] as String? ?? 'Check-in dibatalkan.';
  }

  Future<String> bulkApprove(int eventId, List<int> ids) async {
    final response = await _call(
      () => _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.panitiaBulkApprove(eventId),
        data: {'registration_ids': ids},
      ),
    );

    return response.data?['message'] as String? ?? 'Berhasil.';
  }

  /// Publikasi / kembalikan ke draf / batalkan acara.
  Future<String> eventAction(int eventId, String action, {String? reason}) async {
    final path = switch (action) {
      'publish' => ApiEndpoints.panitiaPublish(eventId),
      'unpublish' => ApiEndpoints.panitiaUnpublish(eventId),
      'cancel' => ApiEndpoints.panitiaCancel(eventId),
      _ => throw ArgumentError('Aksi tidak dikenal: $action'),
    };

    final response = await _call(
      () => _apiClient.post<Map<String, dynamic>>(
        path,
        data: reason == null ? null : {'cancellation_reason': reason},
      ),
    );

    return response.data?['message'] as String? ?? 'Berhasil.';
  }

  Future<Response<Map<String, dynamic>>> _call(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Koneksi internet terputus.');
      }

      final status = e.response?.statusCode;
      final message = (e.response?.data is Map)
          ? (e.response!.data['message'] as String?)
          : null;

      if (status == 403) {
        throw ServerException(
          message ?? 'Kamu tidak punya akses ke acara ini.',
          403,
        );
      }

      if (status == 422) {
        throw ServerException(message ?? 'Tindakan tidak dapat diproses.', 422);
      }

      throw ServerException(message ?? 'Terjadi kesalahan pada server.');
    }
  }
}
