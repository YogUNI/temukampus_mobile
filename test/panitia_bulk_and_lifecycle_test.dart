import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/panitia/data/datasources/panitia_remote_datasource.dart';
import 'package:temukampus_mobile/features/panitia/data/models/panitia_models.dart';
import 'package:temukampus_mobile/features/panitia/presentation/controllers/panitia_controller.dart';
import 'package:temukampus_mobile/features/panitia/presentation/screens/panitia_registrants_screen.dart';
import 'package:temukampus_mobile/features/panitia/presentation/widgets/review_note_sheet.dart';
import 'package:temukampus_mobile/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:temukampus_mobile/features/scanner/data/models/check_in_result_model.dart';

class MockPanitiaDataSource extends PanitiaRemoteDataSource {
  MockPanitiaDataSource() : super(ApiClient(Dio()));

  List<int>? lastBulkApprovedIds;
  int? lastBulkEventId;
  String? lastAction;
  String? lastReason;
  int? lastActionEventId;
  int? lastExportEventId;
  bool? lastExportIsPdf;

  @override
  Future<PanitiaDashboardModel> dashboard() async {
    return const PanitiaDashboardModel(
      eventsTotal: 2,
      registrationsActive: 10,
      pendingVerification: 4,
      confirmed: 6,
      attended: 3,
      confirmedAmount: 250000,
      attendanceRate: 50.0,
    );
  }

  @override
  Future<RegistrantPageModel> registrants(
    int eventId, {
    String tab = 'menunggu',
    String? search,
  }) async {
    if (tab == 'menunggu') {
      return const RegistrantPageModel(
        items: [
          RegistrantModel(
            id: 101,
            ticketCode: 'TK-TEST01',
            status: 'pending_verification',
            name: 'Ahmad Mahasiswa',
            nim: '41524010001',
            studyProgram: 'Teknik Informatika',
            hasProof: true,
          ),
          RegistrantModel(
            id: 102,
            ticketCode: 'TK-TEST02',
            status: 'pending_verification',
            name: 'Budi Santoso',
            nim: '41824010002',
            studyProgram: 'Sistem Informasi',
            hasProof: true,
          ),
        ],
        menunggu: 2,
        terkonfirmasi: 3,
        hadir: 1,
      );
    }

    return const RegistrantPageModel(
      items: [],
      menunggu: 2,
      terkonfirmasi: 3,
      hadir: 1,
    );
  }

  @override
  Future<String> bulkApprove(int eventId, List<int> ids) async {
    lastBulkEventId = eventId;
    lastBulkApprovedIds = ids;
    return '${ids.length} pendaftaran disetujui.';
  }

  @override
  Future<String> eventAction(int eventId, String action, {String? reason}) async {
    lastActionEventId = eventId;
    lastAction = action;
    lastReason = reason;

    return switch (action) {
      'publish' => 'Acara dipublikasikan.',
      'unpublish' => 'Acara dikembalikan ke draf.',
      'cancel' => 'Acara dibatalkan dan peserta dikabari.',
      _ => 'Berhasil.',
    };
  }

  @override
  Future<List<int>> downloadExportBytes(int eventId, {required bool isPdf}) async {
    lastExportEventId = eventId;
    lastExportIsPdf = isPdf;
    return const [1, 2, 3, 4];
  }
}

class MockScannerDataSource extends ScannerRemoteDataSource {
  MockScannerDataSource() : super(ApiClient(Dio()));

  @override
  Future<List<GateEventModel>> getManagedEvents() async {
    return [
      GateEventModel(
        id: 1,
        title: 'Seminar Nasional AI 2026',
        slug: 'seminar-ai-2026',
        location: 'Auditorium Tower UMB',
        startAt: DateTime(2026, 11, 20),
        totalQuota: 100,
        attendedCount: 3,
        registeredCount: 10,
        organizationName: 'BEM FASILKOM',
      ),
    ];
  }
}

void main() {
  group('Panitia Bulk Approve & Event Lifecycle Tests', () {
    test('RegistrantsController.bulkApprove memanggil datasource dengan benar', () async {
      final mock = MockPanitiaDataSource();
      final controller = RegistrantsController(mock, 1);

      await Future.delayed(const Duration(milliseconds: 10));

      final result = await controller.bulkApprove([101, 102]);

      expect(mock.lastBulkEventId, 1);
      expect(mock.lastBulkApprovedIds, [101, 102]);
      expect(result, '2 pendaftaran disetujui.');
    });

    test('RegistrantsController.eventAction memanggil publish, unpublish, cancel', () async {
      final mock = MockPanitiaDataSource();
      final controller = RegistrantsController(mock, 1);

      await Future.delayed(const Duration(milliseconds: 10));

      final resPublish = await controller.eventAction('publish');
      expect(mock.lastAction, 'publish');
      expect(resPublish, 'Acara dipublikasikan.');

      final resUnpublish = await controller.eventAction('unpublish');
      expect(mock.lastAction, 'unpublish');
      expect(resUnpublish, 'Acara dikembalikan ke draf.');

      final resCancel = await controller.eventAction(
        'cancel',
        reason: 'Ruangan auditorium mengalami kendala renovasi.',
      );
      expect(mock.lastAction, 'cancel');
      expect(mock.lastReason, 'Ruangan auditorium mengalami kendala renovasi.');
      expect(resCancel, 'Acara dibatalkan dan peserta dikabari.');
    });

    testWidgets('PanitiaRegistrantsScreen menampilkan menu titik tiga & seleksi massal', (tester) async {
      final mockPanitia = MockPanitiaDataSource();
      final mockScanner = MockScannerDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            panitiaRemoteDataSourceProvider.overrideWithValue(mockPanitia),
            scannerRemoteDataSourceProvider.overrideWithValue(mockScanner),
          ],
          child: const MaterialApp(
            home: PanitiaRegistrantsScreen(eventId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi judul dan nama acara di AppBar
      expect(find.text('Peserta Acara'), findsOneWidget);
      expect(find.text('Seminar Nasional AI 2026'), findsOneWidget);

      // Verifikasi popup menu aksi acara ada di AppBar
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      // Verifikasi daftar peserta di tab Menunggu
      expect(find.text('Ahmad Mahasiswa'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);

      // Verifikasi toolbar "Pilih semua (2 menunggu)" muncul
      expect(find.text('Pilih semua (2 menunggu)'), findsOneWidget);

      // Sebelum dipilih, bottom bar bulk action tidak ada
      expect(find.textContaining('Peserta Terpilih'), findsNothing);

      // Centang checkbox pertama (milik Ahmad Mahasiswa)
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3)); // 1 di header toolbar + 2 di kartu

      // Tap checkbox kartu pertama (index 1)
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Sekarang tombol melayang bulk approve muncul: "Setujui (1) Peserta Terpilih"
      expect(find.text('Setujui (1) Peserta Terpilih'), findsOneWidget);
      expect(find.text('1 dari 2 dipilih'), findsOneWidget);

      // Tap checkbox kedua (index 2)
      await tester.tap(checkboxes.at(2));
      await tester.pumpAndSettle();

      // Sekarang "Setujui (2) Peserta Terpilih"
      expect(find.text('Setujui (2) Peserta Terpilih'), findsOneWidget);
      expect(find.text('2 dari 2 dipilih'), findsOneWidget);

      // Tap tombol "Batal"
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Seleksi bersih dan bottom bar hilang
      expect(find.textContaining('Peserta Terpilih'), findsNothing);
      expect(find.text('Pilih semua (2 menunggu)'), findsOneWidget);
    });

    testWidgets('showReviewNoteSheet validasi minimal karakter dinamis', (tester) async {
      String? submittedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  submittedText = await showReviewNoteSheet(
                    context,
                    title: 'Batalkan Acara',
                    hint: 'Tuliskan alasan pembatalan...',
                    confirmLabel: 'Batalkan Acara',
                    destructive: true,
                    minLength: 10,
                  );
                },
                child: const Text('Buka Sheet'),
              ),
            ),
          ),
        ),
      );

      // Buka bottom sheet
      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      // Sheet terbuka (ada judul "Batalkan Acara" dan tombol "Batalkan Acara")
      expect(find.text('Batalkan Acara'), findsNWidgets(2));
      expect(find.textContaining('Minimal 10 karakter'), findsOneWidget);

      // Tombol submit harus nonaktif ketika teks < 10 karakter
      final confirmBtn = find.widgetWithText(FilledButton, 'Batalkan Acara');
      expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNull);

      // Ketik 5 karakter
      await tester.enterText(find.byType(TextField), 'Kurang');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNull);

      // Ketik lebih dari 10 karakter
      await tester.enterText(find.byType(TextField), 'Alasan pembatalan resmi acara kampus');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNotNull);

      // Submit
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(submittedText, 'Alasan pembatalan resmi acara kampus');
    });

    testWidgets('PopupMenuButton menampilkan opsi Ekspor CSV dan Lembar Hadir PDF', (tester) async {
      final mockPanitia = MockPanitiaDataSource();
      final mockScanner = MockScannerDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            panitiaRemoteDataSourceProvider.overrideWithValue(mockPanitia),
            scannerRemoteDataSourceProvider.overrideWithValue(mockScanner),
          ],
          child: const MaterialApp(
            home: PanitiaRegistrantsScreen(eventId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap menu titik tiga di AppBar
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Pastikan opsi Ekspor Peserta (CSV) dan Unduh Lembar Hadir (PDF) muncul
      expect(find.text('Ekspor Peserta (CSV)'), findsOneWidget);
      expect(find.text('Unduh Lembar Hadir (PDF)'), findsOneWidget);
      expect(find.text('Publikasikan Acara'), findsOneWidget);
      expect(find.text('Kembalikan ke Draf'), findsOneWidget);
      expect(find.text('Batalkan Acara'), findsOneWidget);
    });
  });
}
