import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formatter utilitas resmi untuk Rupiah dan penanggalan WIB di TemuKampus.
class AppFormatters {
  AppFormatters._();

  static bool _isLocaleInitialized = false;

  /// Inisialisasi data lokal penanggalan Indonesia
  static Future<void> initialize() async {
    if (!_isLocaleInitialized) {
      await initializeDateFormatting('id_ID', null);
      _isLocaleInitialized = true;
    }
  }

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Memformat angka ke format Rupiah standar, misal: 25000 -> "Rp 25.000"
  static String rupiah(num amount) {
    return _currencyFormat.format(amount).replaceAll(',00', '');
  }

  /// Memformat kode unik transfer 3 digit, misal: 137 -> "+ Rp 137"
  static String uniqueCode(int code) {
    return "+ Rp $code";
  }

  /// Format tanggal ramah mahasiswa, misal: "Jumat, 20 Nov 2026"
  static String eventDate(DateTime dateTime) {
    try {
      return DateFormat('EEEE, d MMM y', 'id_ID').format(dateTime);
    } catch (_) {
      // Fallback tanpa dependensi locale jika belum terinisialisasi
      const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final dayName = dayNames[dateTime.weekday - 1];
      final monthName = monthNames[dateTime.month - 1];
      return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
    }
  }

  /// Format jam WIB, misal: "09:00 WIB"
  static String eventTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Format rentang waktu acara, misal: "09:00 – 12:30 WIB"
  static String eventTimeRange(DateTime start, DateTime end) {
    return '${eventTime(start).replaceAll(' WIB', '')} – ${eventTime(end)}';
  }
}
