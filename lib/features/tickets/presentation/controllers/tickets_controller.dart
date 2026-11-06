import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/tickets_repository.dart';

class TicketsState {
  final bool isLoading;
  final String activeTab; // 'upcoming', 'pending', 'completed', 'cancelled'
  final List<TicketModel> tickets;
  final String? errorMessage;

  const TicketsState({
    this.isLoading = false,
    this.activeTab = 'upcoming',
    this.tickets = const [],
    this.errorMessage,
  });

  bool get isEmpty => !isLoading && errorMessage == null && tickets.isEmpty;

  TicketsState copyWith({
    bool? isLoading,
    String? activeTab,
    List<TicketModel>? tickets,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TicketsState(
      isLoading: isLoading ?? this.isLoading,
      activeTab: activeTab ?? this.activeTab,
      tickets: tickets ?? this.tickets,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final ticketsControllerProvider =
    StateNotifierProvider<TicketsController, TicketsState>((ref) {
  final repository = ref.watch(ticketsRepositoryProvider);
  return TicketsController(repository);
});

class TicketsController extends StateNotifier<TicketsState> {
  final TicketsRepository _repository;

  TicketsController(this._repository) : super(const TicketsState()) {
    fetchTickets();
  }

  void changeTab(String tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tickets = await _repository.getTickets(tab: state.activeTab);
      state = state.copyWith(
        isLoading: false,
        tickets: tickets,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar tiket Anda. Silakan coba lagi.',
      );
    }
  }

  Future<void> refresh() async {
    await fetchTickets();
  }
}
