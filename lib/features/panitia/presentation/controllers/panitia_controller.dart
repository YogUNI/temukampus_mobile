import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/exceptions.dart';
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

  /// Menyetujui beberapa pendaftaran sekaligus (Fase 9 / F-25 bulk approve).
  Future<String> bulkApprove(List<int> registrationIds) async {
    final message = await _dataSource.bulkApprove(eventId, registrationIds);
    await load(silent: true);

    return message;
  }

  /// Publikasikan, kembalikan ke draf, atau batalkan acara.
  Future<String> eventAction(String action, {String? reason}) async {
    final message = await _dataSource.eventAction(eventId, action, reason: reason);
    await load(silent: true);

    return message;
  }

  /// Ekspor peserta ke CSV atau Lembar Presensi ke PDF, simpan sementara & buka share sheet.
  Future<String> exportFile({required bool isPdf, String? eventSlug}) async {
    final bytes = await _dataSource.downloadExportBytes(eventId, isPdf: isPdf);
    if (bytes.isEmpty) {
      throw const ServerException('Berkas ekspor kosong.');
    }

    final slug = (eventSlug != null && eventSlug.isNotEmpty) ? eventSlug : 'acara-$eventId';
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final mimeType = isPdf ? 'application/pdf' : 'text/csv';
    final filename = isPdf
        ? 'presensi-$slug-$dateStr.pdf'
        : 'peserta-$slug-$dateStr.csv';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: filename)],
        subject: isPdf ? 'Lembar Presensi $slug' : 'Daftar Peserta $slug',
      ),
    );

    return isPdf
        ? 'Lembar hadir berhasil diunduh.'
        : 'Data peserta berhasil diekspor.';
  }
}

final registrantsControllerProvider = StateNotifierProvider.autoDispose
    .family<RegistrantsController, RegistrantsState, int>((ref, eventId) {
  return RegistrantsController(ref.watch(panitiaRemoteDataSourceProvider), eventId);
});
