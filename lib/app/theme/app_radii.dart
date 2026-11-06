import 'package:flutter/widgets.dart';

/// Skala radius resmi TemuKampus Mobile.
///
/// Hanya enam langkah yang diizinkan. Nilai lain (1, 2, 3.5, 5, 10, 14, 18, 22)
/// yang tersebar di layar lama adalah utang desain dan wajib dimigrasikan.
class AppRadii {
  AppRadii._();

  /// Badge, tag kecil, kotak kode.
  static const double xs = 8;

  /// Input, chip kapsul kecil, tombol sekunder.
  static const double sm = 12;

  /// Kartu konten, thumbnail.
  static const double md = 16;

  /// Kartu hero, bottom sheet kecil.
  static const double lg = 20;

  /// Bottom sheet penuh, modal.
  static const double xl = 24;

  /// Dock navigasi, search bar pill, tombol kapsul.
  static const double pill = 999;

  static BorderRadius get borderXs => BorderRadius.circular(xs);
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderPill => BorderRadius.circular(pill);

  /// Sheet yang menempel ke bawah layar.
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xl));
}
