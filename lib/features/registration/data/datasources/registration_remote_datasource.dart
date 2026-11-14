import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/image_compressor.dart';
import '../models/registration_model.dart';

final registrationRemoteDataSourceProvider = Provider<RegistrationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RegistrationRemoteDataSource(apiClient);
});

/// Sumber data pendaftaran acara — seluruhnya memanggil API v1 nyata.
///
/// Tidak ada lagi fallback mock: kegagalan jaringan/validasi diteruskan ke
/// controller sebagai [AppException] agar UI menampilkan pesan & tombol
/// "Coba Lagi" yang sebenarnya.
class RegistrationRemoteDataSource {
  final ApiClient _apiClient;

  RegistrationRemoteDataSource(this._apiClient);

  /// Pratinjau nominal transfer + kode unik 3 digit.
  ///
  /// Kode unik di sini sudah **direservasi** backend, jadi angka yang tampil
  /// sama dengan yang akan tercatat saat pendaftaran dikirim.
  Future<PaymentPreviewModel> getPaymentPreview(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/events/$slug/payment-preview',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return PaymentPreviewModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Kirim formulir pendaftaran & unggah bukti transfer (multipart).
  ///
  /// Status 201 = pendaftaran baru, 200 = idempoten (sudah pernah daftar).
  Future<RegistrationResultModel> submitRegistration({
    required String slug,
    required bool termsAccepted,
    PickedImageData? proofData,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'terms_accepted': termsAccepted ? 1 : 0,
      };

      if (proofData != null) {
        formMap['payment_proof'] = MultipartFile.fromBytes(
          proofData.bytes,
          filename: proofData.fileName,
        );
      }

      final formData = FormData.fromMap(formMap);

      final response = await _apiClient.uploadMultipart<Map<String, dynamic>>(
        ApiEndpoints.registerEvent(slug),
        formData: formData,
        onSendProgress: onProgress,
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return RegistrationResultModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Unggah ulang bukti transfer saat status `needs_revision`.
  Future<String> resubmitProof({
    required String ticketCode,
    required PickedImageData proofData,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'payment_proof': MultipartFile.fromBytes(
          proofData.bytes,
          filename: proofData.fileName,
        ),
      });

      final response = await _apiClient.uploadMultipart<Map<String, dynamic>>(
        '/tickets/$ticketCode/resubmit-proof',
        formData: formData,
        onSendProgress: onProgress,
      );

      return response.data?['message'] as String? ?? 'Bukti pembayaran berhasil diperbarui.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
    }
  }

  /// Jaring pengaman: setiap kegagalan Dio yang belum bertipe jadi
  /// [AppException] tetap diterjemahkan, tidak pernah ditelan diam-diam.
  AppException _asAppException(DioException e) {
    final error = e.error;
    if (error is AppException) return error;

    return ServerException(
      'Tidak dapat menghubungi server TemuKampus. Periksa koneksi lalu coba lagi.',
      e.response?.statusCode,
    );
  }
}
