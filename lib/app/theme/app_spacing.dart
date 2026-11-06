import 'package:flutter/widgets.dart';

/// Skala jarak resmi TemuKampus Mobile (8-point grid).
///
/// Aturan: semua padding, margin, dan gap WAJIB memakai nilai dari kelas ini.
/// Nilai di luar skala (mis. 10, 14, 18) hanya boleh dipakai untuk ketebalan
/// garis/border atau ukuran ikon — bukan untuk jarak antar elemen.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Gutter standar halaman (kiri-kanan).
  static const double gutter = xl;

  /// Padding halaman standar untuk layar dengan scroll.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: gutter, vertical: lg);

  /// Padding halaman tanpa padding vertikal (dipakai di dalam ListView).
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: gutter);

  /// Padding internal kartu standar.
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Padding internal kartu rapat (kartu grid 2-kolom, chip, dsb).
  static const EdgeInsets cardCompact = EdgeInsets.all(md);

  /// Jarak aman bawah agar konten terakhir tidak tertutup dock navigasi.
  static const double dockClearance = 96;
}
