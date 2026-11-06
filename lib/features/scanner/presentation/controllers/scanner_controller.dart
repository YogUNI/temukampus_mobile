import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/check_in_result_model.dart';
import '../../data/repositories/scanner_repository.dart';

class ScannerState {
  final bool isLoading;
  final bool isProcessingScan;
  final bool torchEnabled;
  final CheckInResultModel? lastResult;
  final int attendedCount;
  final int totalQuota;

  const ScannerState({
    this.isLoading = false,
    this.isProcessingScan = false,
    this.torchEnabled = false,
    this.lastResult,
    this.attendedCount = 142,
    this.totalQuota = 200,
  });

  ScannerState copyWith({
    bool? isLoading,
    bool? isProcessingScan,
    bool? torchEnabled,
    CheckInResultModel? lastResult,
    bool clearResult = false,
    int? attendedCount,
    int? totalQuota,
  }) {
    return ScannerState(
      isLoading: isLoading ?? this.isLoading,
      isProcessingScan: isProcessingScan ?? this.isProcessingScan,
      torchEnabled: torchEnabled ?? this.torchEnabled,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      attendedCount: attendedCount ?? this.attendedCount,
      totalQuota: totalQuota ?? this.totalQuota,
    );
  }
}

final scannerControllerProvider = StateNotifierProvider.autoDispose
    .family<ScannerController, ScannerState, int>((ref, eventId) {
  final repository = ref.watch(scannerRepositoryProvider);
  return ScannerController(repository, eventId);
});

class ScannerController extends StateNotifier<ScannerState> {
  final ScannerRepository _repository;
  final int _eventId;

  ScannerController(this._repository, this._eventId)
      : super(const ScannerState());

  void initCounts({int? attended, int? total}) {
    state = state.copyWith(
      attendedCount: attended ?? state.attendedCount,
      totalQuota: total ?? state.totalQuota,
    );
  }

  void toggleTorch() {
    state = state.copyWith(torchEnabled: !state.torchEnabled);
  }

  /// Memproses kode hasil scan kamera
  Future<void> onCodeDetected(String rawCode) async {
    if (state.isProcessingScan || state.lastResult != null) return;

    state = state.copyWith(isProcessingScan: true);

    try {
      final result = await _repository.scanTicket(
        eventId: _eventId,
        ticketCode: rawCode.trim(),
      );

      // Berikan Tactile Haptics yang presisi
      if (result.isSuccess) {
        await AppHaptics.heavy();
        state = state.copyWith(
          isProcessingScan: false,
          lastResult: result,
          attendedCount: state.attendedCount + 1,
        );
      } else if (result.isAlreadyCheckedIn) {
        await AppHaptics.medium();
        state = state.copyWith(
          isProcessingScan: false,
          lastResult: result,
        );
      } else {
        await AppHaptics.error();
        state = state.copyWith(
          isProcessingScan: false,
          lastResult: result,
        );
      }
    } catch (_) {
      await AppHaptics.error();
      state = state.copyWith(
        isProcessingScan: false,
        lastResult: CheckInResultModel(
          status: CheckInStatus.invalidTicket,
          message: 'Gagal memproses kode tiket. Silakan scan ulang.',
          ticketCode: rawCode,
        ),
      );
    }
  }

  /// Presensi manual via input NIM / Kode
  Future<void> submitManualQuery(String query) async {
    state = state.copyWith(isProcessingScan: true);

    try {
      final result = await _repository.manualCheckIn(
        eventId: _eventId,
        query: query.trim(),
      );

      if (result.isSuccess) {
        await AppHaptics.heavy();
        state = state.copyWith(
          isProcessingScan: false,
          lastResult: result,
          attendedCount: state.attendedCount + 1,
        );
      } else if (result.isAlreadyCheckedIn) {
        await AppHaptics.medium();
        state = state.copyWith(
          isProcessingScan: false,
          lastResult: result,
        );
      } else {
        await AppHaptics.error();
        state = state.copyWith(
          isProcessingScan: false,
          lastResult: result,
        );
      }
    } catch (_) {
      await AppHaptics.error();
      state = state.copyWith(
        isProcessingScan: false,
        lastResult: CheckInResultModel(
          status: CheckInStatus.invalidTicket,
          message: 'Peserta tidak ditemukan.',
        ),
      );
    }
  }

  /// Melanjutkan pemindaian setelah modal ditutup
  void resumeScanning() {
    state = state.copyWith(
      isProcessingScan: false,
      clearResult: true,
    );
  }
}

