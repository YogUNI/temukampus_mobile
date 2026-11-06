import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_compressor.dart';
import '../models/registration_model.dart';

final registrationRemoteDataSourceProvider = Provider<RegistrationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RegistrationRemoteDataSource(apiClient);
});

class RegistrationRemoteDataSource {
  final ApiClient _apiClient;

  RegistrationRemoteDataSource(this._apiClient);

  /// Ambil pratinjau nominal transfer & kode unik 3 digit
  Future<PaymentPreviewModel> getPaymentPreview(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/events/$slug/payment-preview',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return PaymentPreviewModel.fromJson(data);
    } on NetworkException {
      return _getMockPaymentPreview(slug);
    } on AppException {
      rethrow;
    } catch (_) {
      return _getMockPaymentPreview(slug);
    }
  }

  /// Kirim formulir pendaftaran & unggah bukti transfer multipart
  Future<RegistrationResultModel> submitRegistration({
    required String slug,
    required bool termsAccepted,
    required bool isPaid,
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
        '/events/$slug/register',
        formData: formData,
        onSendProgress: onProgress,
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      return RegistrationResultModel.fromJson(data);
    } on NetworkException {
      return _mockRegistrationResult(isPaid: isPaid);
    } on AppException {
      rethrow;
    } catch (_) {
      return _mockRegistrationResult(isPaid: isPaid);
    }
  }

  /// Unggah ulang bukti transfer saat status revisi
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
    } catch (_) {
      return 'Bukti pembayaran berhasil dikirimkan kembali (Dev Mock).';
    }
  }

  // === Dev Mock Generator Realistis ===

  PaymentPreviewModel _getMockPaymentPreview(String slug) {
    const basePrice = 25000;
    final randomUnique = 100 + Random().nextInt(899); // 3 digit angka unik
    final total = basePrice + randomUnique;

    return PaymentPreviewModel(
      ticketPrice: basePrice,
      uniqueCode: randomUnique,
      totalAmountDue: total,
      formattedTotal: AppFormatters.rupiah(total),
      bankName: 'BCA (Bank Central Asia)',
      accountNumber: '5410982311',
      accountName: 'HIMA TEKNIK INFORMATIKA UMB',
      qrisUrl: null,
    );
  }

  RegistrationResultModel _mockRegistrationResult({required bool isPaid}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    final ticketCode = 'TK-$randomCode';

    return RegistrationResultModel(
      ticketCode: ticketCode,
      status: isPaid ? 'pending_verification' : 'confirmed',
      statusLabel: isPaid ? 'Menunggu Verifikasi' : 'Terkonfirmasi',
      amountDue: isPaid ? 25137 : 0,
      registeredAt: DateTime.now(),
    );
  }
}
