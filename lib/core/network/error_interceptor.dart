import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

/// Interceptor untuk mentransformasi respon galat HTTP Laravel 13
/// menjadi tipe [AppException] yang mudah diproses UI.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        appException = const NetworkException();
        break;

      case DioExceptionType.badResponse:
        final response = err.response;
        final statusCode = response?.statusCode;
        final data = response?.data;

        if (statusCode == 422 && data is Map<String, dynamic>) {
          // Format Galat Validasi Form Laravel 13
          final message = data['message'] as String? ?? 'Data yang dikirimkan tidak valid.';
          final rawErrors = data['errors'];
          final fieldErrors = <String, List<String>>{};

          if (rawErrors is Map<String, dynamic>) {
            rawErrors.forEach((key, value) {
              if (value is List) {
                fieldErrors[key] = value.map((e) => e.toString()).toList();
              } else if (value is String) {
                fieldErrors[key] = [value];
              }
            });
          }

          appException = ValidationException(
            message: message,
            fieldErrors: fieldErrors,
          );
        } else if (statusCode == 401) {
          final message = (data is Map<String, dynamic> ? data['message'] as String? : null) ??
              'Sesi Anda telah berakhir, silakan masuk kembali.';
          final errorCode = data is Map<String, dynamic> ? data['error_code'] as String? : null;
          appException = AuthException(message, errorCode, statusCode);
        } else {
          final message = (data is Map<String, dynamic> ? data['message'] as String? : null) ??
              'Terjadi kesalahan pada server kampus (Kode: $statusCode).';
          appException = ServerException(message, statusCode);
        }
        break;

      case DioExceptionType.cancel:
        appException = const AppException('Permintaan dibatalkan.');
        break;

      default:
        appException = const ServerException('Terjadi kendala tak terduga. Silakan coba lagi.');
        break;
    }

    return handler.next(
      err.copyWith(
        error: appException,
        message: appException.message,
      ),
    );
  }
}

