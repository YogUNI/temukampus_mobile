import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/tickets_repository.dart';

class TicketDetailState {
  final bool isLoading;
  final bool isSubmitting;
  final TicketModel? ticket;
  final String? errorMessage;
  final String? successMessage;

  const TicketDetailState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.ticket,
    this.errorMessage,
    this.successMessage,
  });

  TicketDetailState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    TicketModel? ticket,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TicketDetailState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      ticket: ticket ?? this.ticket,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

final ticketDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<TicketDetailController, TicketDetailState, String>((ref, ticketCode) {
  final repository = ref.watch(ticketsRepositoryProvider);
  return TicketDetailController(repository, ticketCode);
});

class TicketDetailController extends StateNotifier<TicketDetailState> {
  final TicketsRepository _repository;
  final String _ticketCode;

  TicketDetailController(this._repository, this._ticketCode)
      : super(const TicketDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final ticket = await _repository.getTicketDetail(_ticketCode);
      state = state.copyWith(
        isLoading: false,
        ticket: ticket,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat rincian tiket. Silakan periksa jaringan Anda.',
      );
    }
  }

  Future<bool> cancelTicket() async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final message = await _repository.cancelTicket(_ticketCode);
      if (state.ticket != null) {
        state = state.copyWith(
          isSubmitting: false,
          ticket: state.ticket!.copyWith(status: 'cancelled', statusLabel: 'Dibatalkan'),
          successMessage: message,
        );
      }
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal membatalkan tiket. Silakan coba kembali.',
      );
      return false;
    }
  }

  Future<bool> resubmitProof(PickedImageData proofData) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final message = await _repository.resubmitProof(
        ticketCode: _ticketCode,
        proofData: proofData,
      );

      if (state.ticket != null) {
        state = state.copyWith(
          isSubmitting: false,
          ticket: state.ticket!.copyWith(
            status: 'pending_verification',
            statusLabel: 'Menunggu Verifikasi',
          ),
          successMessage: message,
        );
      }
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal mengunggah ulang bukti pembayaran. Silakan coba lagi.',
      );
      return false;
    }
  }
}
