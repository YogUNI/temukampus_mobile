import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_spacing.dart';

/// Sumber tunggal matematika grid acara 2-kolom.
///
/// Kartu grid TIDAK boleh memakai `childAspectRatio`: rasio membuat tinggi kartu
/// bergantung pada lebar layar sementara isi kartu berukuran tetap, sehingga
/// terjadi overflow di lebar 360–412dp. Sebagai gantinya tinggi kartu dihitung
/// eksplisit dari: tinggi poster (16:10) + tinggi blok konten yang diukur.
class EventGridMetrics {
  EventGridMetrics._();

  static const int columns = 2;
  static const double gap = AppSpacing.md;
  static const double posterAspectRatio = 16 / 10;

  /// Tinggi minimum blok konten di bawah poster (padding + ormawa + 2 baris
  /// judul + tanggal + baris harga/panah). Diverifikasi oleh
  /// `event_grid_layout_test.dart` di lebar 360–430dp.
  static const double contentHeight = 144;

  static double tileWidth(double gridWidth) =>
      (gridWidth - gap * (columns - 1)) / columns;

  static double tileHeight(double gridWidth) =>
      tileWidth(gridWidth) / posterAspectRatio + contentHeight;

  static SliverGridDelegateWithFixedCrossAxisCount delegate(double gridWidth) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      mainAxisExtent: tileHeight(gridWidth),
    );
  }
}
