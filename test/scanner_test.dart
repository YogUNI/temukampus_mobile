import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:temukampus_mobile/features/scanner/data/models/check_in_result_model.dart';
import 'package:temukampus_mobile/features/scanner/data/repositories/scanner_repository.dart';
import 'package:temukampus_mobile/features/scanner/presentation/controllers/scanner_controller.dart';

import 'helpers/fake_api.dart';

/// Backend memutuskan hasil pemindaian; aplikasi hanya menerjemahkan.
/// Fixture diambil dari respons API v1 sungguhan.
ScannerRemoteDataSource buildDataSource() {
  final adapter = FakeApiAdapter([
    FakeRoute(
      method: 'POST',
      path: '/panitia/check-in/scan',
      bodyMatch: {'ticket_code': 'TK-BU44Z4'},
      body: apiFixture('check_in_success.json'),
    ),
    FakeRoute(
      method: 'POST',
      path: '/panitia/check-in/scan',
      bodyMatch: {'ticket_code': 'TK-SUDAH01'},
      body: apiFixture('check_in_already.json'),
    ),
    FakeRoute(
      method: 'POST',
      path: '/panitia/check-in/scan',
      body: apiFixture('check_in_invalid.json'),
    ),
    FakeRoute(
      method: 'POST',
      path: '/panitia/check-in/manual',
      bodyMatch: {'query': '41121000051'},
      body: apiFixture('check_in_success.json'),
    ),
    FakeRoute(
      method: 'POST',
      path: '/panitia/check-in/manual',
      body: apiFixture('check_in_invalid.json'),
    ),
    FakeRoute(method: 'GET', path: '/panitia/events', body: apiFixture('organizer_events.json')),
    FakeRoute(method: 'GET', path: '/organizer/events', body: apiFixture('organizer_events.json')),
  ]);

  return ScannerRemoteDataSource(fakeApiClient(adapter));
}

void main() {
  group('CheckInResultModel Unit Tests', () {
    test('Berhasil parse CheckInResultModel status SUCCESS', () {
      final json = {
        'status': 'SUCCESS',
        'message': 'Peserta berhasil check-in.',
        'data': {
          'ticket_code': 'TK-7F3KQ9',
          'checked_in_at': '2026-11-20T08:32:15Z',
          'participant': {
            'name': 'Yoga Gustira',
            'nim': '41524010001',
            'study_program': 'Teknik Informatika',
            'cohort_year': 2024,
          },
        },
      };

      final result = CheckInResultModel.fromJson(json);

      expect(result.status, equals(CheckInStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyCheckedIn, isFalse);
      expect(result.isInvalid, isFalse);
      expect(result.ticketCode, equals('TK-7F3KQ9'));
      expect(result.participant?.name, equals('Yoga Gustira'));
      expect(result.participant?.nim, equals('41524010001'));
    });

    test('Berhasil parse CheckInResultModel status ALREADY_CHECKED_IN', () {
      final json = {
        'status': 'ALREADY_CHECKED_IN',
        'message': 'Tiket ini sudah pernah dipindai pada 08:15 WIB.',
        'data': {
          'first_checked_in_at': '2026-11-20T08:15:20Z',
          'participant_name': 'Yoga Gustira',
        },
      };

      final result = CheckInResultModel.fromJson(json);

      expect(result.status, equals(CheckInStatus.alreadyCheckedIn));
      expect(result.isAlreadyCheckedIn, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.participant?.name, equals('Yoga Gustira'));
    });

    test('Berhasil parse CheckInResultModel status INVALID_TICKET', () {
      final json = {
        'status': 'INVALID_TICKET',
        'message': 'Kode tiket tidak valid atau bukan terdaftar untuk acara ini.',
      };

      final result = CheckInResultModel.fromJson(json);

      expect(result.status, equals(CheckInStatus.invalidTicket));
      expect(result.isInvalid, isTrue);
      expect(result.isSuccess, isFalse);
    });
  });

  group('Scanner Remote Data Source & Flow Tests', () {
    late ScannerRemoteDataSource dataSource;

    setUp(() {
      dataSource = buildDataSource();
    });

    test('Scan tiket valid menghasilkan SUCCESS beserta data peserta', () async {
      final result = await dataSource.scanTicket(eventId: 7, ticketCode: 'TK-BU44Z4');

      expect(result.isSuccess, isTrue);
      expect(result.participant?.name, equals('Peserta 51'));
      expect(result.participant?.nim, equals('41121000051'));
      expect(result.ticketCode, equals('TK-BU44Z4'));
    });

    test('Scan tiket yang sudah dipakai menghasilkan ALREADY_CHECKED_IN', () async {
      final result = await dataSource.scanTicket(eventId: 7, ticketCode: 'TK-SUDAH01');

      expect(result.isAlreadyCheckedIn, isTrue);
      expect(result.message, contains('sudah check-in'));
    });

    test('Scan kode asing menghasilkan INVALID_TICKET', () async {
      final result = await dataSource.scanTicket(eventId: 7, ticketCode: 'TK-NGAWUR');

      expect(result.isInvalid, isTrue);
      expect(result.message, contains('tidak terdaftar'));
    });

    test('Presensi manual via NIM peserta berhasil', () async {
      final result = await dataSource.manualCheckIn(eventId: 7, query: '41121000051');

      expect(result.status, isNot(CheckInStatus.invalidTicket));
      expect(result.participant?.nim, equals('41121000051'));
    });

    test('Daftar acara panitia dimuat dari API', () async {
      final events = await dataSource.getManagedEvents();

      expect(events, isNotEmpty);
      expect(events.first.title, contains('Seminar Karier'));
      expect(events.first.registeredCount, 19);
    });
  });

  group('ScannerController State Machine Tests', () {
    late ScannerController controller;
    late ScannerRepository repository;

    setUp(() {
      repository = ScannerRepository(buildDataSource());
      controller = ScannerController(repository, 7);
    });

    test('Inisialisasi kuota dan counter kehadiran', () {
      controller.initCounts(attended: 100, total: 200);

      expect(controller.state.attendedCount, equals(100));
      expect(controller.state.totalQuota, equals(200));
    });

    test('Toggle torch kamera mengubah status senter', () {
      expect(controller.state.torchEnabled, isFalse);
      controller.toggleTorch();
      expect(controller.state.torchEnabled, isTrue);
      controller.toggleTorch();
      expect(controller.state.torchEnabled, isFalse);
    });

    test('Resume scanning membersihkan lastResult', () async {
      await controller.onCodeDetected('TK-BU44Z4');
      expect(controller.state.lastResult, isNotNull);

      controller.resumeScanning();
      expect(controller.state.lastResult, isNull);
      expect(controller.state.isProcessingScan, isFalse);
    });
  });
}

