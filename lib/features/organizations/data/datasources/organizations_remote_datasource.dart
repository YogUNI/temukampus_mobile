import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/organization_model.dart';

final organizationsRemoteDataSourceProvider = Provider<OrganizationsRemoteDataSource>((ref) {
  return OrganizationsRemoteDataSource(ref.watch(apiClientProvider));
});

/// Sumber data direktori organisasi. Semua penyaringan dilakukan server
/// (sama seperti halaman /organisasi di web) supaya hasilnya identik.
class OrganizationsRemoteDataSource {
  final ApiClient _apiClient;

  OrganizationsRemoteDataSource(this._apiClient);

  Future<OrganizationDirectoryModel> getDirectory({
    String? group,
    String? search,
    int? facultyId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.organizations,
        queryParameters: {
          if (group != null && group.isNotEmpty) 'tipe': group,
          if (search != null && search.isNotEmpty) 'q': search,
          if (facultyId != null && facultyId > 0) 'fakultas': facultyId,
        },
      );

      return OrganizationDirectoryModel.fromJson(response.data ?? {});
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  Future<OrganizationDetailModel> getDetail(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.organizationDetail(slug),
      );

      return OrganizationDetailModel.fromJson(response.data ?? {});
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  AppException _asAppException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException('Koneksi internet terputus.');
    }

    final status = e.response?.statusCode;

    if (status == 401) {
      return const AuthException('Sesi Anda telah berakhir, silakan masuk kembali.');
    }

    if (status == 404) {
      return const ServerException('Organisasi tidak ditemukan.', 404);
    }

    return ServerException('Terjadi kesalahan pada server. Coba lagi.');
  }
}
