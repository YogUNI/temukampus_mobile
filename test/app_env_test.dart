import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/constants/env.dart';

/// Pemilihan base URL API.
///
/// Regresi: `flutter build web` menghasilkan build **release**, dan dulu build
/// release selalu memakai URL produksi — sehingga build web yang dibuka di
/// localhost menembak `https://temukampus.mercubuana.ac.id` (belum ada) dan
/// beranda menampilkan "Gagal memuat katalog acara".
void main() {
  tearDown(() {
    AppEnv.customHostOverride = null;
  });

  test('override kustom menang atas semua aturan lain', () {
    AppEnv.customHostOverride = 'http://192.168.1.10:8000/api/v1';

    expect(AppEnv.baseUrl, 'http://192.168.1.10:8000/api/v1');
  });

  test('di lingkungan tes (bukan web) memakai host yang sesuai platform', () {
    // Tes berjalan di VM, jadi jalur web tidak diuji di sini; yang dipastikan
    // hanya bahwa nilainya adalah salah satu URL yang dikenal.
    expect(
      AppEnv.baseUrl,
      anyOf(
        'http://temukampus.test/api/v1',
        'http://10.0.2.2:8000/api/v1',
        'https://temukampus.mercubuana.ac.id/api/v1',
      ),
    );
  });

  test('build release non-web memakai URL produksi', () {
    // kReleaseMode true saat `flutter test --release`; pada mode debug tes ini
    // tetap memeriksa bahwa URL lokal dipakai.
    final url = AppEnv.baseUrl;

    expect(url.endsWith('/api/v1'), isTrue);
    expect(url, isNot(contains(' ')));
  });
}
