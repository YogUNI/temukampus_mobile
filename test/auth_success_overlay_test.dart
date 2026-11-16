import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/auth/presentation/widgets/auth_success_overlay.dart';

/// Kartu konfirmasi keberhasilan (login & pendaftaran).
///
/// Kontraknya: judul, pesan, dan catatan tampil di atas gradasi cobalt, lalu
/// overlay menutup sendiri setelah [kAuthSuccessDuration] — bukan menunggu
/// pengguna mengetuk apa pun. Alur "pendaftaran → overlay → verifikasi kode"
/// diuji terpisah lewat tes alur masuk yang sudah ada.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan judul, pesan, dan catatan', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AuthSuccessOverlay(
          title: 'Akun Berhasil Dibuat',
          message: 'Kami mengirim kode verifikasi 6 digit ke emailmu.',
          footnote: 'Akun Mahasiswa UMB',
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Akun Berhasil Dibuat'), findsOneWidget);
    expect(
      find.text('Kami mengirim kode verifikasi 6 digit ke emailmu.'),
      findsOneWidget,
    );
    expect(find.text('Akun Mahasiswa UMB'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('menutup sendiri setelah durasi animasi selesai', (tester) async {
    var popped = false;

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await showAuthSuccessOverlay(
                context,
                title: 'Berhasil Masuk',
                message: 'Selamat datang kembali.',
              );
              popped = true;
            },
            child: const Text('Picu'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Picu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AuthSuccessOverlay), findsOneWidget);
    expect(find.text('Berhasil Masuk'), findsOneWidget);

    // Durasi total + transisi dialog, tanpa interaksi pengguna.
    await tester.pumpAndSettle(
      kAuthSuccessDuration + const Duration(milliseconds: 600),
    );

    expect(find.byType(AuthSuccessOverlay), findsNothing);
    expect(popped, isTrue);
  });

  testWidgets('animasi selesai (tidak ada timer yang tertinggal)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const AuthSuccessOverlay(
          title: 'Pendaftaran Berhasil',
          message: 'Tiket dan status akan dikirim lewat notifikasi.',
        ),
      ),
    );

    await tester.pumpAndSettle(kAuthSuccessDuration + const Duration(seconds: 1));

    // Tidak ada exception "A Timer is still pending" saat teardown.
    expect(tester.takeException(), isNull);
  });
}
