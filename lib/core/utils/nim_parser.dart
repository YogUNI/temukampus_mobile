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

  const NimResult({
    required this.isValid,
    this.rawNim,
    this.programCode,
    this.programName,
    this.facultyName,
    this.cohortYear,
    this.sequenceNumber,
    this.errorMessage,
  });

  /// Ringkasan ramah UI, misal "Teknik Informatika '24"
  String? get summary {
    if (!isValid || programName == null || cohortYear == null) return null;
    final shortYear = cohortYear.toString().substring(2);
    return "$programName '$shortYear";
  }
}

/// Parser NIM resmi Mahasiswa Universitas Mercu Buana (UMB).
/// Sesuai aturan domain BR-01, BR-02, BR-03:
/// - Panjang tepat 11 digit numerik.
/// - Digit 1–3: Kode Program Studi (e.g. 415 -> Teknik Informatika, 418 -> Sistem Informasi).
/// - Digit 4–5: Angkatan Mahasiswa (20 + YY, e.g. 24 -> 2024).
/// - Digit 6–11: Nomor urut unik mahasiswa.
class NimParser {
  NimParser._();

  static const Map<String, (String programName, String facultyName)> _programDictionary = {
    // Fakultas Ilmu Komputer (FASILKOM)
    '415': ('Teknik Informatika', 'Fakultas Ilmu Komputer'),
    '418': ('Sistem Informasi', 'Fakultas Ilmu Komputer'),

    // Fakultas Teknik (FT)
    '411': ('Teknik Arsitektur', 'Fakultas Teknik'),
    '412': ('Teknik Mesin', 'Fakultas Teknik'),
    '413': ('Teknik Elektro', 'Fakultas Teknik'),
    '414': ('Teknik Sipil', 'Fakultas Teknik'),
    '416': ('Teknik Industri', 'Fakultas Teknik'),

    // Fakultas Ekonomi dan Bisnis (FEB)
    '421': ('Manajemen', 'Fakultas Ekonomi dan Bisnis'),
    '422': ('Akuntansi', 'Fakultas Ekonomi dan Bisnis'),

    // Fakultas Ilmu Komunikasi (FIKOM)
    '441': ('Ilmu Komunikasi', 'Fakultas Ilmu Komunikasi'),
    '442': ('Hubungan Masyarakat (PR)', 'Fakultas Ilmu Komunikasi'),
    '443': ('Broadcasting (Penyiaran)', 'Fakultas Ilmu Komunikasi'),
    '444': ('Periklanan & Komunikasi Pemasaran', 'Fakultas Ilmu Komunikasi'),

    // Fakultas Psikologi
    '461': ('Psikologi', 'Fakultas Psikologi'),

    // Fakultas Desain dan Seni Kreatif (FDSK)
    '551': ('Desain Produk', 'Fakultas Desain dan Seni Kreatif'),
    '552': ('Desain Interior', 'Fakultas Desain dan Seni Kreatif'),
    '553': ('Desain Komunikasi Visual (DKV)', 'Fakultas Desain dan Seni Kreatif'),
  };

  /// Memvalidasi dan mengekstrak info akademik dari NIM 11 digit.
  static NimResult parse(String? rawNim) {
    if (rawNim == null || rawNim.trim().isEmpty) {
      return const NimResult(
        isValid: false,
        errorMessage: 'NIM tidak boleh kosong.',
      );
    }

    final cleaned = rawNim.trim();

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
    final yearSuffix = cleaned.substring(3, 5);
    final sequence = cleaned.substring(5, 11);

    final parsedYearSuffix = int.tryParse(yearSuffix);
    if (parsedYearSuffix == null) {
      return const NimResult(
        isValid: false,
        errorMessage: 'Format tahun angkatan pada NIM tidak valid.',
      );
    }

    // Rentang tahun 2000-2099
    final cohortYear = 2000 + parsedYearSuffix;

    final programInfo = _programDictionary[programCode];
    final programName = programInfo?.$1 ?? 'Program Studi $programCode';
    final facultyName = programInfo?.$2 ?? 'Universitas Mercu Buana';

    return NimResult(
      isValid: true,
      rawNim: cleaned,
      programCode: programCode,
      programName: programName,
      facultyName: facultyName,
      cohortYear: cohortYear,
      sequenceNumber: sequence,
    );
  }
}

