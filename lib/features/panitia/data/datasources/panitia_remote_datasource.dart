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

  /// Unduh byte berkas ekspor data peserta CSV atau lembar hadir PDF.
  Future<List<int>> downloadExportBytes(int eventId, {required bool isPdf}) async {
    final path = isPdf
        ? ApiEndpoints.panitiaAttendanceSheet(eventId)
        : ApiEndpoints.panitiaExportCsv(eventId);

    try {
      final response = await _apiClient.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data ?? <int>[];
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Koneksi internet terputus.');
      }

      final status = e.response?.statusCode;
      if (status == 403) {
        throw const ServerException('Kamu tidak punya akses ke acara ini.', 403);
      }

      throw const ServerException('Gagal mengunduh berkas ekspor.');
    }
  }

  /// Ambil metadata untuk formulir buat/ubah acara (kategori, fakultas, prodi).
  Future<PanitiaEventMetaModel> getEventsMeta() async {
    final response = await _call(
      () => _apiClient.get<Map<String, dynamic>>(ApiEndpoints.panitiaEventsMeta),
    );
    return PanitiaEventMetaModel.fromJson(response.data ?? {});
  }

  /// Detail acara untuk formulir ubah acara.
  Future<PanitiaEventDetailModel> getEventDetail(int eventId) async {
    final response = await _call(
      () => _apiClient.get<Map<String, dynamic>>(ApiEndpoints.panitiaEventDetail(eventId)),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PanitiaEventDetailModel.fromJson(data);
  }

  /// Simpan acara (POST untuk buat baru, POST/PUT untuk ubah acara).
  Future<Map<String, dynamic>> saveEvent(FormData formData, {int? eventId}) async {
    final path = eventId != null
        ? ApiEndpoints.panitiaEventUpdate(eventId)
        : ApiEndpoints.panitiaEventCreate;
    final response = await _call(
      () => _apiClient.post<Map<String, dynamic>>(
        path,
        data: formData,
      ),
    );
    return response.data ?? {};
  }

  /// Ambil profil organisasi aktif panitia.
  Future<PanitiaOrganizationModel> getOrganization() async {
    final response = await _call(
      () => _apiClient.get<Map<String, dynamic>>(ApiEndpoints.panitiaOrganization),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PanitiaOrganizationModel.fromJson(data);
  }

  /// Perbarui profil organisasi (nama, deskripsi, instagram, email, logo).
  Future<PanitiaOrganizationModel> updateOrganization(FormData formData) async {
    final response = await _call(
      () => _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.panitiaOrganization,
        data: formData,
      ),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PanitiaOrganizationModel.fromJson(data);
  }

  /// Daftar staf / anggota organisasi.
  Future<List<PanitiaMemberModel>> getMembers() async {
    final response = await _call(
      () => _apiClient.get<Map<String, dynamic>>(ApiEndpoints.panitiaMembers),
    );
    final list = response.data?['data'] as List<dynamic>? ?? [];
    return list.map((e) => PanitiaMemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Undang staf baru lewat email.
  Future<String> inviteMember(String email) async {
    final response = await _call(
      () => _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.panitiaMembers,
        data: {'email': email},
      ),
    );
    return response.data?['message'] as String? ?? 'Anggota berhasil ditambahkan.';
  }

  /// Hapus staf dari organisasi.
  Future<String> removeMember(int userId) async {
    final response = await _call(
      () => _apiClient.delete<Map<String, dynamic>>(
        ApiEndpoints.panitiaMemberRemove(userId),
      ),
    );
    return response.data?['message'] as String? ?? 'Anggota berhasil dihapus.';
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
        final rawErrors = (e.response?.data is Map)
            ? (e.response!.data['errors'] as Map<String, dynamic>?)
            : null;
        final Map<String, List<String>> fieldErrors = {};
        if (rawErrors != null) {
          rawErrors.forEach((key, value) {
            if (value is List) {
              fieldErrors[key] = value.map((item) => item.toString()).toList();
            } else if (value != null) {
              fieldErrors[key] = [value.toString()];
            }
          });
        }
        throw ValidationException(
          message: message ?? 'Data yang dikirimkan tidak valid.',
          fieldErrors: fieldErrors,
        );
      }

      throw ServerException(message ?? 'Terjadi kesalahan pada server.');
    }
  }
}
