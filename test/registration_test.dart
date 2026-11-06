import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/core/utils/image_compressor.dart';
import 'package:temukampus_mobile/features/registration/data/datasources/registration_remote_datasource.dart';
import 'package:temukampus_mobile/features/registration/data/models/registration_model.dart';
import 'package:temukampus_mobile/features/registration/data/repositories/registration_repository.dart';
import 'package:temukampus_mobile/features/registration/presentation/controllers/registration_controller.dart';
import 'package:temukampus_mobile/features/registration/presentation/controllers/registration_state.dart';

void main() {
  group('Registration Model & Payment Preview Tests', () {
    test('Berhasil parse PaymentPreviewModel dengan kode unik 3 digit', () {
      final json = {
        'ticket_price': 25000,
        'unique_code': 137,
        'total_amount_due': 25137,
        'formatted_total': 'Rp 25.137',
        'bank_name': 'Bank Central Asia (BCA)',
        'account_number': '5410982311',
        'account_name': 'HIMA TEKNIK INFORMATIKA UMB',
        'qris_url': 'http://temukampus.test/qris.png',
      };

      final model = PaymentPreviewModel.fromJson(json);

      expect(model.ticketPrice, equals(25000));
      expect(model.uniqueCode, equals(137));
      expect(model.totalAmountDue, equals(25137));
      expect(model.formattedTotal, equals('Rp 25.137'));
      expect(model.bankName, equals('Bank Central Asia (BCA)'));
      expect(model.hasBankInfo, isTrue);
      expect(model.hasQris, isTrue);
    });

    test('Berhasil parse RegistrationModel dari JSON', () {
      final json = {
        'ticket_code': 'TK-7F3KQ9',
        'status': 'pending_verification',
        'status_label': 'Menunggu Verifikasi',
        'amount_due': 25137,
        'unique_code': 137,
        'registered_at': '2026-11-06T14:20:00Z',
      };

      final model = RegistrationModel.fromJson(json);

      expect(model.ticketCode, equals('TK-7F3KQ9'));
      expect(model.status, equals('pending_verification'));
      expect(model.isPendingVerification, isTrue);
      expect(model.isConfirmed, isFalse);
      expect(model.amountDue, equals(25137));
    });
  });

  group('RegistrationController State Flow Tests', () {
    late RegistrationController controller;
    late RegistrationRepository repository;

    setUp(() {
      final apiClient = ApiClient(Dio());
      final remoteDataSource = RegistrationRemoteDataSource(apiClient);
      repository = RegistrationRepository(remoteDataSource);
      controller = RegistrationController(repository, 'seminar-ai-2026');
    });

    test('Memuat Payment Preview untuk acara berbayar', () async {
      await controller.loadPaymentPreview(isPaid: true);

      expect(controller.state.status, equals(RegistrationStatus.ready));
      expect(controller.state.paymentPreview, isNotNull);
      expect(controller.state.paymentPreview!.totalAmountDue, greaterThan(0));
    });

    test('Persetujuan syarat dan ketentuan (toggleTerms)', () {
      expect(controller.state.termsAccepted, isFalse);
      controller.toggleTerms(true);
      expect(controller.state.termsAccepted, isTrue);
      controller.toggleTerms(false);
      expect(controller.state.termsAccepted, isFalse);
    });

    test('Submit ditolak jika syarat & ketentuan belum disetujui', () async {
      final success = await controller.submit(isPaid: false);

      expect(success, isFalse);
      expect(controller.state.status, equals(RegistrationStatus.error));
      expect(controller.state.errorMessage, contains('wajib menyetujui'));
    });

    test('Submit acara berbayar ditolak jika belum ada bukti transfer', () async {
      controller.toggleTerms(true);
      final success = await controller.submit(isPaid: true);

      expect(success, isFalse);
      expect(controller.state.status, equals(RegistrationStatus.error));
      expect(controller.state.errorMessage, contains('Bukti pembayaran'));
    });

    test('Submit acara gratis berhasil setelah menyetujui syarat', () async {
      controller.toggleTerms(true);
      final success = await controller.submit(isPaid: false);

      expect(success, isTrue);
      expect(controller.state.status, equals(RegistrationStatus.success));
      expect(controller.state.result, isNotNull);
      expect(controller.state.result!.ticketCode.startsWith('TK-'), isTrue);
    });

    test('Submit acara berbayar berhasil jika ada bukti transfer', () async {
      controller.toggleTerms(true);
      final dummyProof = PickedImageData(
        file: XFile('dummy.jpg'),
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        sizeInBytes: 4,
        fileName: 'dummy.jpg',
      );

      // Simulasikan state bukti terunggah
      controller.state = controller.state.copyWith(selectedProof: dummyProof);

      final success = await controller.submit(isPaid: true);

      expect(success, isTrue);
      expect(controller.state.status, equals(RegistrationStatus.success));
      expect(controller.state.result!.ticketCode.startsWith('TK-'), isTrue);
    });
  });
}
