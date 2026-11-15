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
  ///
  /// Slug mengikuti tabel `categories` di API: `seminar` dan `workshop` (bukan
  /// `akademik`/tag). Bila ada filter aktif yang tidak punya chip — format,
  /// tag, harga maksimum, organisasi, atau kategori lain — kembalikan himpunan
  /// kosong: menyalakan "Semua" saat filter aktif itu menyesatkan, karena
  /// katalog bisa kosong padahal chip terlihat seperti tanpa filter.
  static Set<int> activeIndexes(EventsCatalogState state) {
    final active = <int>{};
    if (state.selectedCategory == 'seminar') active.add(2);
    if (state.selectedCategory == 'workshop') active.add(4);
    if (state.onlyFree) active.add(1);
    if (state.onlySkp) active.add(3);
    if (state.suitableForMe) active.add(5);

    if (active.isEmpty) {
      return state.hasActiveFilter ? const <int>{} : const {0};
    }

    return active;
  }
}
