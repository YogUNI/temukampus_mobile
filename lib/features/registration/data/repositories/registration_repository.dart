import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/image_compressor.dart';
import '../datasources/registration_remote_datasource.dart';
import '../models/registration_model.dart';

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  final remoteDataSource = ref.watch(registrationRemoteDataSourceProvider);
  return RegistrationRepository(remoteDataSource);
});

class RegistrationRepository {
  final RegistrationRemoteDataSource _remoteDataSource;

  RegistrationRepository(this._remoteDataSource);

  Future<PaymentPreviewModel> getPaymentPreview(String slug) async {
    return await _remoteDataSource.getPaymentPreview(slug);
  }

  Future<RegistrationResultModel> submitRegistration({
    required String slug,
    required bool termsAccepted,
    required bool isPaid,
    PickedImageData? proofData,
    void Function(int sent, int total)? onProgress,
  }) async {
    return await _remoteDataSource.submitRegistration(
      slug: slug,
      termsAccepted: termsAccepted,
      isPaid: isPaid,
      proofData: proofData,
      onProgress: onProgress,
    );
  }

  Future<String> resubmitProof({
    required String ticketCode,
    required PickedImageData proofData,
    void Function(int sent, int total)? onProgress,
  }) async {
    return await _remoteDataSource.resubmitProof(
      ticketCode: ticketCode,
      proofData: proofData,
      onProgress: onProgress,
    );
  }
}
