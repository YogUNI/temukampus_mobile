import '../../../../core/utils/image_compressor.dart';
import '../../data/models/registration_model.dart';

enum RegistrationStatus {
  initial,
  loadingPreview,
  ready,
  submitting,
  success,
  error,
}

class RegistrationState {
  final RegistrationStatus status;
  final PaymentPreviewModel? paymentPreview;
  final PickedImageData? selectedProof;
  final bool isCompressing;
  final bool termsAccepted;
  final double uploadProgress;
  final RegistrationResultModel? result;
  final String? errorMessage;

  const RegistrationState({
    this.status = RegistrationStatus.initial,
    this.paymentPreview,
    this.selectedProof,
    this.isCompressing = false,
    this.termsAccepted = false,
    this.uploadProgress = 0.0,
    this.result,
    this.errorMessage,
  });

  bool get isLoading =>
      status == RegistrationStatus.loadingPreview ||
      status == RegistrationStatus.submitting ||
      isCompressing;

  bool get isSubmitting => status == RegistrationStatus.submitting;
  bool get isSuccess => status == RegistrationStatus.success;

  bool canSubmit({required bool isPaid}) {
    if (!termsAccepted) return false;
    if (isSubmitting || isCompressing) return false;
    if (isPaid && selectedProof == null) return false;
    return true;
  }

  RegistrationState copyWith({
    RegistrationStatus? status,
    PaymentPreviewModel? paymentPreview,
    PickedImageData? selectedProof,
    bool clearProof = false,
    bool? isCompressing,
    bool? termsAccepted,
    double? uploadProgress,
    RegistrationResultModel? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegistrationState(
      status: status ?? this.status,
      paymentPreview: paymentPreview ?? this.paymentPreview,
      selectedProof: clearProof ? null : (selectedProof ?? this.selectedProof),
      isCompressing: isCompressing ?? this.isCompressing,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

