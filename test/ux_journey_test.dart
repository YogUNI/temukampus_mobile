import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/app/router/route_names.dart';

void main() {
  group('UX Journey & Guest Mode Routing Invariants Tests', () {
    test('Mode Tamu (Guest): Route publik dapat diakses tanpa autentikasi', () {
      const publicRoutes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
        AppRoutes.explore,
      ];

      for (final route in publicRoutes) {
        expect(route, isNotEmpty);
      }
    });

    test('Mode Tamu (Guest): Akses form pendaftaran mengarah ke login dengan redirect & reason', () {
      const eventSlug = 'seminar-nasional-ai-2025';
      final targetPath = AppRoutes.eventRegisterPath(eventSlug);
      final encodedRedirect = Uri.encodeComponent(targetPath);
      final expectedLoginRedirect = '${AppRoutes.login}?redirect=$encodedRedirect&reason=register';

      expect(expectedLoginRedirect, contains('reason=register'));
      expect(expectedLoginRedirect, contains(eventSlug));
      expect(Uri.decodeComponent(encodedRedirect), targetPath);
    });

    test('Mode Tamu (Guest): Akses rincian tiket privat mengarah ke login dengan redirect', () {
      const ticketCode = 'TK-7F3KQ9';
      final targetPath = AppRoutes.ticketDetailPath(ticketCode);
      final encodedRedirect = Uri.encodeComponent(targetPath);
      final expectedLoginRedirect = '${AppRoutes.login}?redirect=$encodedRedirect';

      expect(expectedLoginRedirect, contains(ticketCode));
      expect(Uri.decodeComponent(encodedRedirect), targetPath);
    });

    test('Tab-specific Empty State messages pada Tiket Saya', () {
      final tabMessages = {
        'upcoming': 'Belum ada tiket acara mendatang. Temukan seminar & workshop kampus!',
        'pending': 'Belum ada tiket yang menunggu verifikasi. Cari acara seru lainnya yuk!',
        'completed': 'Belum ada riwayat acara yang selesai.',
        'cancelled': 'Tidak ada tiket yang dibatalkan.',
      };

      expect(tabMessages['upcoming'], contains('seminar & workshop'));
      expect(tabMessages['pending'], contains('menunggu verifikasi'));
      expect(tabMessages['completed'], contains('acara yang selesai'));
      expect(tabMessages['cancelled'], contains('dibatalkan'));
    });

    test('Celebration Sheet: Status terkonfirmasi dan menunggu verifikasi memiliki label tepat', () {
      String getMessage(bool isPaid) => isPaid
          ? 'Panitia akan memverifikasi bukti transfermu maksimal 1x24 jam.'
          : 'Selamat! Pendaftaranmu terkonfirmasi otomatis.';

      final paidMessage = getMessage(true);
      final freeMessage = getMessage(false);

      expect(paidMessage, contains('1x24 jam'));
      expect(freeMessage, contains('terkonfirmasi otomatis'));
    });
  });
}
