import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Bahasa elevasi resmi TemuKampus Mobile.
///
/// Ada dua bahasa visual yang sengaja dipisah per-peran:
/// - [AppShadows] (soft, ber-tint) untuk CHROME aplikasi: kartu katalog,
///   sheet, search bar, dock navigasi.
/// - [sticker] (hard-shadow ink) HANYA untuk artefak tiket, stempel status,
///   dan tombol aksi utama — tanda tangan visual TemuKampus.
///
/// Mencampur keduanya pada satu permukaan membuat UI terasa berisik.
class AppShadows {
  AppShadows._();

  /// Bayangan standar kartu di atas kanvas Paper.
  static const BoxShadow soft = BoxShadow(
    color: Color(0x0F12162B),
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  /// Kartu yang perlu terlihat "melayang" (hero, dock, sheet).
  static const BoxShadow lifted = BoxShadow(
    color: Color(0x1A12162B),
    offset: Offset(0, 8),
    blurRadius: 24,
  );

  /// Dock navigasi mengambang di atas konten.
  static const BoxShadow dock = BoxShadow(
    color: Color(0x2412162B),
    offset: Offset(0, 10),
    blurRadius: 28,
  );

  static const List<BoxShadow> softCard = [soft];
  static const List<BoxShadow> liftedCard = [lifted];
  static const List<BoxShadow> dockBar = [dock];

  /// Stiker keras — hanya untuk artefak tiket & CTA utama.
  static const List<BoxShadow> sticker = [AppColors.stickerShadow];
  static const List<BoxShadow> stickerSmall = [AppColors.stickerShadowSmall];
  static const List<BoxShadow> stickerLarge = [AppColors.stickerShadowLarge];
}

/// Blur & opasitas untuk efek kaca (glassmorphism) pada tombol di atas poster.
class AppGlass {
  AppGlass._();

  static const double blur = 12;
  static const double surfaceOpacity = 0.18;
  static const double borderOpacity = 0.35;
}

/// Durasi animasi resmi — dijaga agar konsisten di seluruh aplikasi.
class AppDurations {
  AppDurations._();

  /// Perubahan warna/opasitas kecil (chip, tombol).
  static const Duration fast = Duration(milliseconds: 150);

  /// Transisi state standar (toggle, expand).
  static const Duration base = Duration(milliseconds: 220);

  /// Transisi antar tampilan (grid <-> list, halaman).
  static const Duration slow = Duration(milliseconds: 320);
}
