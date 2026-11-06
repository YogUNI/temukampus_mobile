import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../data/repositories/registration_repository.dart';
import 'registration_state.dart';

final registrationControllerProvider = StateNotifierProvider.autoDispose
    .family<RegistrationController, RegistrationState, String>((ref, slug) {
  final repository = ref.watch(registrationRepositoryProvider);
  return RegistrationController(repository, slug);
});

class RegistrationController extends StateNotifier<RegistrationState> {
  final RegistrationRepository _repository;
  final String _slug;

  RegistrationController(this._repository, this._slug)
      : super(const RegistrationState());

  /// Memuat pratinjau nominal transfer & kode unik 3 digit
  Future<void> loadPaymentPreview({required bool isPaid}) async {
    if (!isPaid) {
      state = state.copyWith(status: RegistrationStatus.ready);
      return;
    }

    state = state.copyWith(status: RegistrationStatus.loadingPreview, clearError: true);

    try {
      final preview = await _repository.getPaymentPreview(_slug);
      state = state.copyWith(
        status: RegistrationStatus.ready,
        paymentPreview: preview,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: 'Gagal memuat instruksi pembayaran. Silakan periksa jaringan Anda.',
      );
    }
  }

  /// Mengambil foto bukti pembayaran dari kamera atau galeri dengan kompresi otomatis
  Future<void> pickProof(ImageSource source) async {
    state = state.copyWith(isCompressing: true, clearError: true);

    try {
      final pickedData = await AppImageHelper.pickImage(source);
      if (pickedData != null) {
        state = state.copyWith(
          selectedProof: pickedData,
          isCompressing: false,
        );
      } else {
        state = state.copyWith(isCompressing: false);
      }
    } catch (_) {
      state = state.copyWith(
        isCompressing: false,
        errorMessage: 'Gagal mengambil atau mengompresi gambar bukti transfer.',
      );
    }
  }

  /// Menghapus foto bukti transfer yang telah dipilih
  void removeProof() {
    state = state.copyWith(clearProof: true);
  }

  /// Mengubah status persetujuan syarat & ketentuan
  void toggleTerms(bool? value) {
    state = state.copyWith(termsAccepted: value ?? false);
  }

  /// Mengirim formulir pendaftaran acara
  Future<bool> submit({required bool isPaid}) async {
    if (!state.termsAccepted) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: 'Anda wajib menyetujui syarat & ketentuan sebelum mendaftar.',
      );
      return false;
    }

    if (isPaid && state.selectedProof == null) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: 'Bukti pembayaran transfer wajib diunggah untuk acara berbayar.',
      );
      return false;
    }

    state = state.copyWith(
      status: RegistrationStatus.submitting,
      uploadProgress: 0.05,
      clearError: true,
    );

    try {
      final result = await _repository.submitRegistration(
        slug: _slug,
        termsAccepted: state.termsAccepted,
        isPaid: isPaid,
        proofData: state.selectedProof,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: (sent / total).clamp(0.1, 0.95));
          }
        },
      );

      state = state.copyWith(
        status: RegistrationStatus.success,
        uploadProgress: 1.0,
        result: result,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: RegistrationStatus.error,
        errorMessage: 'Terjadi kesalahan saat mengirim pendaftaran. Silakan coba kembali.',
      );
      return false;
    }
  }
}

