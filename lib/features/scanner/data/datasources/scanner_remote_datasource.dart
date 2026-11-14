import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/check_in_result_model.dart';

final scannerRemoteDataSourceProvider = Provider<ScannerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ScannerRemoteDataSource(apiClient);
});

/// Sumber data scanner pintu & presensi manual panitia.
///
/// Semua keputusan (valid/tidak, sudah check-in, bukan tiket acara ini)
/// diputuskan backend lewat action `CheckInParticipant` — aplikasi hanya
/// menampilkan hasilnya, sehingga aturan pintu identik dengan panel web.
class ScannerRemoteDataSource {
  final ApiClient _apiClient;

  ScannerRemoteDataSource(this._apiClient);

  /// Pindai kode QR tiket (`POST /panitia/check-in/scan`).
  Future<CheckInResultModel> scanTicket({
    required int eventId,
    required String ticketCode,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/panitia/check-in/scan',
        data: {
          'event_id': eventId,
          'ticket_code': ticketCode.trim(),
        },
      );

      return CheckInResultModel.fromJson(response.data!);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Presensi manual lewat NIM atau nama peserta (`POST /panitia/check-in/manual`).
  Future<CheckInResultModel> manualCheckIn({
    required int eventId,
    required String query,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/panitia/check-in/manual',
        data: {
          'event_id': eventId,
          'query': query.trim(),
        },
      );

      return CheckInResultModel.fromJson(response.data!);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Daftar acara yang dikelola panitia (`GET /panitia/events`).
  Future<List<GateEventModel>> getManagedEvents() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.organizerEvents);
      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => GateEventModel.fromJson(e as Map<String, dynamic>)).toList();
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
