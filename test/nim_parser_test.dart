import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/utils/nim_parser.dart';

/// Kontrak data NIM ↔ program studi.
///
/// Tabel di sini adalah salinan `database/seeders/data/study_programs.csv`
/// (repo web). Kalau salah satu kode berubah di backend, tes ini gagal —
/// itulah tujuannya: pratinjau di aplikasi tidak boleh menampilkan prodi
/// yang berbeda dari yang tercatat di server.
void main() {
  /// Kode → (nama prodi, nama fakultas) persis seperti di database.
  const expected = <String, (String, String)>{
    '411': ('Teknik Sipil', 'Fakultas Teknik'),
    '412': ('Teknik Arsitektur', 'Fakultas Teknik'),
    '413': ('Teknik Mesin', 'Fakultas Teknik'),
    '414': ('Teknik Elektro', 'Fakultas Teknik'),
    '415': ('Teknik Informatika', 'Fakultas Ilmu Komputer'),
    '416': ('Teknik Industri', 'Fakultas Teknik'),
    '417': ('Desain Interior', 'Fakultas Desain dan Seni Kreatif'),
    '418': ('Sistem Informasi', 'Fakultas Ilmu Komputer'),
    '419': ('Desain Produk', 'Fakultas Desain dan Seni Kreatif'),
    '423': ('Desain Komunikasi Visual', 'Fakultas Desain dan Seni Kreatif'),
    '431': ('Manajemen', 'Fakultas Ekonomi dan Bisnis'),
    '432': ('Akuntansi', 'Fakultas Ekonomi dan Bisnis'),
    '441': ('Broadcasting', 'Fakultas Ilmu Komunikasi'),
    '442': ('Public Relations', 'Fakultas Ilmu Komunikasi'),
    '443': ('Marketing Komunikasi', 'Fakultas Ilmu Komunikasi'),
    '445': ('Digital Komunikasi', 'Fakultas Ilmu Komunikasi'),
    '461': ('Psikologi', 'Fakultas Psikologi'),
  };

  group('pemetaan 3 digit awal NIM', () {
    expected.forEach((code, names) {
      test('kode $code = ${names.$1}', () {
        final result = NimParser.parse('${code}24010001');

        expect(result.isValid, isTrue);
        expect(result.programCode, code);
        expect(result.programName, names.$1);
        expect(result.facultyName, names.$2);
        expect(result.isUnknownProgram, isFalse);
      });
    });

    test('jumlah prodi yang dikenal sama dengan tabel backend (17)', () {
      expect(NimParser.knownProgramCodes.length, expected.length);
      expect(NimParser.knownProgramCodes, expected.keys.toList()..sort());
    });
  });

  group('angkatan', () {
    test('NIM 41524010010 → Teknik Informatika angkatan 2024', () {
      final result = NimParser.parse('41524010010', now: DateTime(2026));

      expect(result.programName, 'Teknik Informatika');
      expect(result.cohortYear, 2024);
      expect(result.summary, "Teknik Informatika '24");
      expect(result.sequenceNumber, '010010');
    });

    test('NIM 41121000001 → Teknik Sipil angkatan 2021', () {
      final result = NimParser.parse('41121000001', now: DateTime(2026));

      expect(result.programName, 'Teknik Sipil');
      expect(result.cohortYear, 2021);
    });

    test('angkatan melewati tahun berjalan ditolak (BR-03)', () {
      final result = NimParser.parse('41599010010', now: DateTime(2026));

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Angkatan 2099'));
    });

    test('angkatan sama dengan tahun berjalan diterima', () {
      final result = NimParser.parse('41526010010', now: DateTime(2026));

      expect(result.isValid, isTrue);
      expect(result.cohortYear, 2026);
    });
  });

  group('format', () {
    test('spasi dan tanda hubung dibersihkan', () {
      final result = NimParser.parse('415-2401-0010', now: DateTime(2026));

      expect(result.isValid, isTrue);
      expect(result.rawNim, '41524010010');
    });

    test('kurang dari 11 digit ditolak', () {
      final result = NimParser.parse('4152401001', now: DateTime(2026));

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('11 digit'));
    });

    test('mengandung huruf ditolak', () {
      final result = NimParser.parse('4152401001A', now: DateTime(2026));

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('digit angka'));
    });

    test('kosong ditolak', () {
      expect(NimParser.parse('').isValid, isFalse);
      expect(NimParser.parse(null).isValid, isFalse);
    });
  });

  test('kode prodi tak dikenal tetap valid tetapi ditandai (paritas backend)', () {
    final result = NimParser.parse('99924010010', now: DateTime(2026));

    expect(result.isValid, isTrue);
    expect(result.isUnknownProgram, isTrue);
    expect(result.programName, isNull);
    expect(result.facultyName, isNull);
    expect(result.cohortYear, 2024);
  });
}
