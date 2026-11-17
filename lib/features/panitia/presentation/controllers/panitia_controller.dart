import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scanner/data/datasources/scanner_remote_datasource.dart';
import '../../../scanner/data/models/check_in_result_model.dart';
import '../../data/datasources/panitia_remote_datasource.dart';
import '../../data/models/panitia_models.dart';

/// Ringkasan panel panitia (jumlah acara, menunggu verifikasi, hadir, dst).
final panitiaDashboardProvider = FutureProvider.autoDispose<PanitiaDashboardModel>((ref) {
  return ref.watch(panitiaRemoteDataSourceProvider).dashboard();
});

/// Acara yang dikelola pengguna ini (dipakai hub & pemilih scanner).
final panitiaEventsProvider = FutureProvider.autoDispose<List<GateEventModel>>((ref) {
  return ref.watch(scannerRemoteDataSourceProvider).getManagedEvents();
});

/// Tab daftar peserta.
enum RegistrantTab {
  menunggu('menunggu', 'Menunggu'),
  terkonfirmasi('terkonfirmasi', 'Terkonfirmasi'),
  hadir('hadir', 'Hadir');

  const RegistrantTab(this.value, this.label);

  final String value;
  final String label;
}

/// State daftar peserta satu acara: tab aktif, pencarian, data, dan status muat.
class RegistrantsState {
  final bool isLoading;
  final String? errorMessage;
  final RegistrantTab tab;
  final RegistrantPageModel page;
  final String search;

  const RegistrantsState({
    this.isLoading = false,
    this.errorMessage,
    this.tab = RegistrantTab.menunggu,
    this.page = const RegistrantPageModel(),
    this.search = '',
  });

  bool get isEmpty => !isLoading && errorMessage == null && page.items.isEmpty;

  int countFor(RegistrantTab tab) => switch (tab) {
        RegistrantTab.menunggu => page.menunggu,
        RegistrantTab.terkonfirmasi => page.terkonfirmasi,
        RegistrantTab.hadir => page.hadir,
      };

  RegistrantsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    RegistrantTab? tab,
    RegistrantPageModel? page,
    String? search,
  }) {
    return RegistrantsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      tab: tab ?? this.tab,
      page: page ?? this.page,
      search: search ?? this.search,
    );
  }
}

class RegistrantsController extends StateNotifier<RegistrantsState> {
  final PanitiaRemoteDataSource _dataSource;
  final int eventId;

  RegistrantsController(this._dataSource, this.eventId)
      : super(const RegistrantsState()) {
    load();
  }

  Future<void> load({
    RegistrantTab? tab,
    String? search,
    bool silent = false,
  }) async {
    final nextTab = tab ?? state.tab;
    final nextQuery = search ?? state.search;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true, tab: nextTab, search: nextQuery);
    }

    try {
      final page = await _dataSource.registrants(
        eventId,
        tab: nextTab.value,
        search: nextQuery,
      );

      if (!mounted) return;

      state = state.copyWith(isLoading: false, page: page, clearError: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Jalankan aksi lalu muat ulang diam-diam supaya daftar tetap segar.
  Future<String> runAction({
    required int registrationId,
    required String action,
    String? reviewNote,
  }) async {
    final message = await _dataSource.act(
      registrationId: registrationId,
      action: action,
      reviewNote: reviewNote,
    );

    await load(silent: true);

    return message;
  }

  Future<String> cancelCheckIn(int registrationId) async {
    final message = await _dataSource.cancelCheckIn(registrationId);
    await load(silent: true);

    return message;
  }
}

final registrantsControllerProvider = StateNotifierProvider.autoDispose
    .family<RegistrantsController, RegistrantsState, int>((ref, eventId) {
  return RegistrantsController(ref.watch(panitiaRemoteDataSourceProvider), eventId);
});
