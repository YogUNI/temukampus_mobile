import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

class EventDetailState {
  final bool isLoading;
  final String? errorMessage;
  final EventDetailModel? detail;
  final EligibilityResultModel? eligibility;

  const EventDetailState({
    this.isLoading = false,
    this.errorMessage,
    this.detail,
    this.eligibility,
  });

  EventDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    EventDetailModel? detail,
    EligibilityResultModel? eligibility,
  }) {
    return EventDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      detail: detail ?? this.detail,
      eligibility: eligibility ?? this.eligibility,
    );
  }
}

final eventDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<EventDetailController, EventDetailState, String>((ref, slug) {
  final repository = ref.watch(eventsRepositoryProvider);
  return EventDetailController(repository, slug);
});

class EventDetailController extends StateNotifier<EventDetailState> {
  final EventsRepository _repository;
  final String slug;

  EventDetailController(this._repository, this.slug) : super(const EventDetailState(isLoading: true)) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final detail = await _repository.getEventDetail(slug);
      final eligibility = await _repository.checkEligibility(slug);

      state = state.copyWith(
        isLoading: false,
        detail: detail,
        eligibility: eligibility,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat detail acara. Silakan coba lagi.',
      );
    }
  }

  Future<void> refreshEligibility() async {
    try {
      final eligibility = await _repository.checkEligibility(slug);
      state = state.copyWith(eligibility: eligibility);
    } catch (_) {}
  }
}
