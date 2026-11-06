import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:temukampus_mobile/features/scanner/data/models/check_in_result_model.dart';
import 'package:temukampus_mobile/features/scanner/data/repositories/scanner_repository.dart';
import 'package:temukampus_mobile/features/scanner/presentation/controllers/scanner_controller.dart';

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
      final apiClient = ApiClient(Dio());
      dataSource = ScannerRemoteDataSource(apiClient);
    });

    test('Scan tiket baru valid menghasilkan SUCCESS', () async {
      final result = await dataSource.scanTicket(
        eventId: 1,
        ticketCode: 'TK-7F3KQ9',
      );

      expect(result.isSuccess, isTrue);
      expect(result.participant?.name, contains('Yoga'));
    });

    test('Scan tiket yang sama kedua kali menghasilkan ALREADY_CHECKED_IN', () async {
      // Tiket TK-7F3KQ9 sudah dipindai di test sebelumnya
      final result = await dataSource.scanTicket(
        eventId: 1,
        ticketCode: 'TK-7F3KQ9',
      );

      expect(result.isAlreadyCheckedIn, isTrue);
      expect(result.message, contains('sudah pernah dipindai'));
    });

    test('Scan kode tiket acak menghasilkan INVALID_TICKET', () async {
      final result = await dataSource.scanTicket(
        eventId: 1,
        ticketCode: 'RANDOM-CODE-123',
      );

      expect(result.isInvalid, isTrue);
      expect(result.message, contains('tidak terdaftar'));
    });

    test('Presensi manual via NIM 41524010001 berhasil', () async {
      final result = await dataSource.manualCheckIn(
        eventId: 1,
        query: '41524010001',
      );

      // Karena TK-7F3KQ9 sudah di-scan, mengembalikan ALREADY_CHECKED_IN atau SUCCESS
      expect(result.status != CheckInStatus.invalidTicket, isTrue);
    });
  });

  group('ScannerController State Machine Tests', () {
    late ScannerController controller;
    late ScannerRepository repository;

    setUp(() {
      final apiClient = ApiClient(Dio());
      final remoteDataSource = ScannerRemoteDataSource(apiClient);
      repository = ScannerRepository(remoteDataSource);
      controller = ScannerController(repository, 1);
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
      await controller.onCodeDetected('TK-NEWPASS99');
      expect(controller.state.lastResult, isNotNull);

      controller.resumeScanning();
      expect(controller.state.lastResult, isNull);
      expect(controller.state.isProcessingScan, isFalse);
    });
  });
}

