/// Hasil parsing NIM Mahasiswa Universitas Mercu Buana (UMB).
class NimResult {
  final bool isValid;
  final String? rawNim;
  final String? programCode;
  final String? programName;
  final String? facultyName;
  final int? cohortYear;
  final String? sequenceNumber;
  final String? errorMessage;

  /// Kode prodi tidak ada di tabel referensi `study_programs`.
  ///
  /// Backend tetap menerima NIM seperti ini (kolom `study_program_id` dibiarkan
  /// kosong), jadi ini peringatan, bukan penghalang.
  final bool isUnknownProgram;

  const NimResult({
    required this.isValid,
    this.rawNim,
    this.programCode,
    this.programName,
    this.facultyName,
    this.cohortYear,
    this.sequenceNumber,
    this.errorMessage,
    this.isUnknownProgram = false,
  });

  /// Ringkasan ramah UI, misal "Teknik Informatika '24"
  String? get summary {
    if (!isValid || programName == null || cohortYear == null) return null;
    final shortYear = cohortYear.toString().substring(2);
    return "$programName '$shortYear";
  }
}

/// Parser NIM resmi Mahasiswa Universitas Mercu Buana (UMB).
///
/// Sumber kebenaran: tabel `study_programs` di backend
/// (`database/seeders/data/study_programs.csv`) — 17 program studi.
/// Aturan domain BR-01..BR-03:
/// - Panjang tepat 11 digit numerik.
/// - Digit 1–3: kode program studi (415 = Teknik Informatika, 411 = Teknik Sipil, …).
/// - Digit 4–5: dua digit terakhir angkatan (20 + YY, mis. 24 → 2024),
///   dan angkatan tidak boleh melewati tahun berjalan.
/// - Digit 6–11: nomor urut mahasiswa.
class NimParser {
  NimParser._();

  /// Kode prodi → (nama prodi, nama fakultas).
  ///
  /// WAJIB identik dengan `study_programs.csv` + `faculties.csv` di repo web.
  /// Sebelumnya tabel ini salah hampir seluruhnya (411 tertukar dengan 415,
  /// 441/443 tertukar, 419/417/423 memakai kode lama 551/552/553), sehingga
  /// pratinjau menampilkan prodi yang tidak sesuai NIM.
  static const Map<String, (String programName, String facultyName)> _programDictionary = {
    // Fakultas Teknik (FT)
    '411': ('Teknik Sipil', 'Fakultas Teknik'),
    '412': ('Teknik Arsitektur', 'Fakultas Teknik'),
    '413': ('Teknik Mesin', 'Fakultas Teknik'),
    '414': ('Teknik Elektro', 'Fakultas Teknik'),
    '416': ('Teknik Industri', 'Fakultas Teknik'),

    // Fakultas Ilmu Komputer (FASILKOM)
    '415': ('Teknik Informatika', 'Fakultas Ilmu Komputer'),
    '418': ('Sistem Informasi', 'Fakultas Ilmu Komputer'),

    // Fakultas Desain dan Seni Kreatif (FDSK)
    '417': ('Desain Interior', 'Fakultas Desain dan Seni Kreatif'),
    '419': ('Desain Produk', 'Fakultas Desain dan Seni Kreatif'),
    '423': ('Desain Komunikasi Visual', 'Fakultas Desain dan Seni Kreatif'),

    // Fakultas Ekonomi dan Bisnis (FEB)
    '431': ('Manajemen', 'Fakultas Ekonomi dan Bisnis'),
    '432': ('Akuntansi', 'Fakultas Ekonomi dan Bisnis'),

    // Fakultas Ilmu Komunikasi (FIKOM)
    '441': ('Broadcasting', 'Fakultas Ilmu Komunikasi'),
    '442': ('Public Relations', 'Fakultas Ilmu Komunikasi'),
    '443': ('Marketing Komunikasi', 'Fakultas Ilmu Komunikasi'),
    '445': ('Digital Komunikasi', 'Fakultas Ilmu Komunikasi'),

    // Fakultas Psikologi (FPSI)
    '461': ('Psikologi', 'Fakultas Psikologi'),
  };

  /// Semua kode program studi yang dikenal (untuk tes & dokumentasi).
  static List<String> get knownProgramCodes => _programDictionary.keys.toList()..sort();

  /// Memvalidasi dan mengekstrak info akademik dari NIM 11 digit.
  static NimResult parse(String? rawNim, {DateTime? now}) {
    if (rawNim == null || rawNim.trim().isEmpty) {
      return const NimResult(
        isValid: false,
        errorMessage: 'NIM tidak boleh kosong.',
      );
    }

    // Spasi dan tanda hubung dibersihkan lebih dulu (E-02 di sisi web).
    final cleaned = rawNim.replaceAll(RegExp(r'[\s-]+'), '').trim();

    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return const NimResult(
        isValid: false,
        errorMessage: 'NIM hanya boleh berisi digit angka.',
      );
    }

    if (cleaned.length != 11) {
      return NimResult(
        isValid: false,
        errorMessage: 'NIM harus tepat 11 digit angka (saat ini ${cleaned.length} digit).',
      );
    }

    final programCode = cleaned.substring(0, 3);
    final yearSuffix = int.tryParse(cleaned.substring(3, 5));
    final sequence = cleaned.substring(5, 11);

    if (yearSuffix == null) {
      return const NimResult(
        isValid: false,
        errorMessage: 'Format tahun angkatan pada NIM tidak valid.',
      );
    }

    // 2000 + YY, dan tidak boleh melewati tahun berjalan (BR-03).
    final cohortYear = 2000 + yearSuffix;
    final currentYear = (now ?? DateTime.now()).year;

    if (cohortYear < 2000 || cohortYear > currentYear) {
      return NimResult(
        isValid: false,
        errorMessage: 'Angkatan $cohortYear belum valid. Tahun angkatan maksimal $currentYear.',
      );
    }

    final programInfo = _programDictionary[programCode];

    return NimResult(
      isValid: true,
      rawNim: cleaned,
      programCode: programCode,
      programName: programInfo?.$1,
      facultyName: programInfo?.$2,
      cohortYear: cohortYear,
      sequenceNumber: sequence,
      isUnknownProgram: programInfo == null,
    );
  }
}
