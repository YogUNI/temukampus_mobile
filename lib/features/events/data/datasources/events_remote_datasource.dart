import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/event_model.dart';

final eventsRemoteDataSourceProvider = Provider<EventsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventsRemoteDataSource(apiClient);
});

class EventsRemoteDataSource {
  final ApiClient _apiClient;

  EventsRemoteDataSource(this._apiClient);

  /// Mengambil daftar acara di katalog / beranda dengan filter
  Future<List<EventModel>> getEvents({
    EventFilterModel? filterModel,
    String? search,
    String? category,
    String? format,
    String? tag,
    bool? suitableForMe,
    int page = 1,
  }) async {
    try {
      final queryParams = filterModel?.toQueryParams() ??
          <String, dynamic>{
            'page': page,
            if (search != null && search.isNotEmpty) 'search': search,
            if (category != null && category.isNotEmpty) 'category': category,
            if (format != null && format.isNotEmpty) 'format': format,
            if (tag != null && tag.isNotEmpty) 'tag': tag,
            if (suitableForMe == true) 'suitable_for_me': 1,
          };

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.events,
        queryParameters: queryParams,
      );

      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Mengambil detail acara lengkap berdasarkan slug
  Future<EventDetailModel> getEventDetail(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.eventDetail(slug),
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return EventDetailModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Memeriksa kelayakan pendaftaran mahasiswa untuk acara tertentu
  Future<EligibilityResultModel> checkEligibility(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.eventEligibility(slug),
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return EligibilityResultModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Mengambil daftar kategori acara
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.categories);
      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
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
