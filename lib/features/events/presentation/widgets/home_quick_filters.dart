import '../controllers/events_catalog_controller.dart';

/// Definisi chip filter cepat di Beranda beserta pemetaan state → chip aktif.
///
/// Sebelumnya indeks chip disimpan sebagai state lokal layar, sehingga chip bisa
/// tetap terlihat "aktif" padahal filter sebenarnya sudah direset dari layar
/// lain. Sekarang chip adalah turunan murni dari [EventsCatalogState].
class HomeQuickFilters {
  HomeQuickFilters._();

  static const String all = 'Semua';
  static const String free = 'Gratis';
  static const String seminar = 'Seminar';
  static const String skp = 'Ber-SKP';
  static const String workshop = 'Workshop';
  static const String suitable = 'Cocok untuk Saya';

  static const List<String> labels = [all, free, seminar, skp, workshop, suitable];

  /// Indeks chip yang harus tampil aktif untuk [state] saat ini.
  static Set<int> activeIndexes(EventsCatalogState state) {
    final active = <int>{};
    if (state.selectedCategory == 'akademik') active.add(2);
    if (state.onlyFree) active.add(1);
    if (state.onlySkp) active.add(3);
    if (state.selectedTag == 'workshop') active.add(4);
    if (state.suitableForMe) active.add(5);
    return active.isEmpty ? const {0} : active;
  }
}
