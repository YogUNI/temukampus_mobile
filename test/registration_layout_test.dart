import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/core/utils/image_compressor.dart';
import 'package:temukampus_mobile/features/registration/data/models/registration_model.dart';
import 'package:temukampus_mobile/features/registration/presentation/widgets/registration_payment_card.dart';
import 'package:temukampus_mobile/features/registration/presentation/widgets/registration_proof_upload_card.dart';
import 'package:temukampus_mobile/features/registration/presentation/widgets/registration_submit_bar.dart';

EventModel _event() => EventModel.fromJson({
      'id': 1,
      'title': 'Seminar Nasional Artificial Intelligence',
      'slug': 'seminar-ai',
      'summary': 'Ringkasan',
      'start_at': '2026-12-01T09:00:00Z',
      'end_at': '2026-12-01T12:00:00Z',
      'location': 'Auditorium UMB',
      'price': 25000,
      'quota': 100,
      'registered_count': 40,
      'format': 'offline',
      'audience': 'umb_only',
      'status': 'published',
      'poster_url': 'assets/images/posters/poster_ai_seminar.jpg',
      'bank_name': 'BCA',
      'bank_account_number': '5410982311',
      'bank_account_name': 'PANITIA SEMINAR',
      'organization': {'id': 1, 'name': 'BEM Fakultas Teknik', 'slug': 'bem-teknik'},
    });

const _preview = PaymentPreviewModel(
  ticketPrice: 25000,
  uniqueCode: 137,
  totalAmountDue: 25137,
  formattedTotal: 'Rp 25.137',
  bankName: 'BCA',
  accountNumber: '5410982311',
  accountName: 'PANITIA SEMINAR',
);

void main() {
  group('RegistrationPaymentCard', () {
    testWidgets('kode unik tampil sebagai hero & tombol salin mengirim kode',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? copied;
      String? message;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: RegistrationPaymentCard(
              preview: _preview,
              event: _event(),
              onCopy: (text, msg) {
                copied = text;
                message = msg;
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('KODE UNIK 3 DIGIT'), findsOneWidget);
      expect(find.text('137'), findsOneWidget);
      expect(find.text('+ Rp 137'), findsOneWidget);
      expect(find.text('Rp 25.137'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Salin'));
      await tester.pump();
      expect(copied, '137');
      expect(message, contains('disalin'));
    });

    testWidgets('ukuran hero kode unik menonjol (>= 32pt)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: RegistrationPaymentCard(
              preview: _preview,
              event: _event(),
              onCopy: (_, __) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final code = tester.widget<Text>(find.text('137'));
      expect(code.style!.fontSize, RegistrationPaymentCard.uniqueCodeHeroSize);
      expect(code.style!.fontSize, greaterThanOrEqualTo(32));
    });
  });

  group('RegistrationSubmitBar', () {
    Future<double> pumpBar(
      WidgetTester tester, {
      required bool isPaid,
      required bool canSubmit,
      bool isSubmitting = false,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: RegistrationSubmitBar(
            isPaid: isPaid,
            isSubmitting: isSubmitting,
            canSubmit: canSubmit,
            totalText: 'Rp 25.137',
            onPressed: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(RegistrationSubmitBar)).height;
    }

    testWidgets('total di kiri, tombol di kanan, tinggi sama untuk 3 keadaan',
        (tester) async {
      final paid = await pumpBar(tester, isPaid: true, canSubmit: true);
      expect(find.text('Rp 25.137'), findsOneWidget);
      expect(find.text('Kirim & Bukti Bayar'), findsOneWidget);

      final priceRect = tester.getRect(find.text('Rp 25.137'));
      final buttonRect = tester.getRect(find.text('Kirim & Bukti Bayar'));
      expect(priceRect.right, lessThan(buttonRect.left));
      expect(buttonRect.center.dx, greaterThan(195));

      final free = await pumpBar(tester, isPaid: false, canSubmit: true);
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('Konfirmasi Gratis'), findsOneWidget);

      final blocked = await pumpBar(tester, isPaid: true, canSubmit: false);
      expect(free, paid);
      expect(blocked, paid);
    });

    testWidgets('tidak bisa dikirim saat syarat belum lengkap', (tester) async {
      await pumpBar(tester, isPaid: true, canSubmit: false);
      // Tombol disabled = tidak ada onTap yang berjalan (GestureDetector tanpa handler).
      await tester.tap(find.text('Kirim & Bukti Bayar'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    });
  });

  group('RegistrationProofUploadCard', () {
    testWidgets('dropzone tampil saat belum ada bukti', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: RegistrationProofUploadCard(
              selectedProof: null,
              isCompressing: false,
              onPick: () {},
              onPreview: (_, __) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Klik untuk Pilih Bukti Transfer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('indikator kompresi muncul saat isCompressing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: RegistrationProofUploadCard(
              selectedProof: null,
              isCompressing: true,
              onPick: () {},
              onPreview: (_, __) {},
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mengompres bukti transfer…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Klik untuk Pilih Bukti Transfer'), findsNothing);
    });

    testWidgets('pratinjau thumbnail tampil & bisa diketuk untuk diperbesar',
        (tester) async {
      final bytes = kTransparentImage;
      final proof = PickedImageData(
        file: XFile.fromData(bytes, name: 'bukti-transfer.png'),
        bytes: bytes,
        sizeInBytes: bytes.length,
        fileName: 'bukti-transfer.png',
      );

      Uint8List? previewed;
      var previewCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: RegistrationProofUploadCard(
              selectedProof: proof,
              isCompressing: false,
              onPick: () {},
              onPreview: (data, name) {
                previewed = data;
                previewCount++;
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bukti Siap Diunggah'), findsOneWidget);
      expect(find.text('bukti-transfer.png'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(previewCount, 1);
      expect(previewed, isNotNull);
    });
  });
}

/// PNG transparan 1x1 untuk pratinjau di tes.
final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
