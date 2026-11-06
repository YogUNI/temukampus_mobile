import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('Berhasil parse UserModel Mahasiswa UMB dari JSON', () {
      final json = {
        'id': 14,
        'name': 'Yoga Gustira',
        'email': 'yoga@mercubuana.ac.id',
        'role': 'user',
        'account_type': 'umb',
        'nim': '41524010001',
        'phone': '081234567890',
        'avatar_url': null,
        'study_program': {
          'id': 1,
          'code': '415',
          'name': 'Teknik Informatika',
        },
        'cohort_year': 2024,
        'email_verified': true,
        'is_organizer': false,
        'status': 'active',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals(14));
      expect(user.name, equals('Yoga Gustira'));
      expect(user.isUmbStudent, isTrue);
      expect(user.academicSummary, equals("Teknik Informatika '24"));
      expect(user.isSuspended, isFalse);
      expect(user.canScanTickets, isFalse);
    });

    test('Berhasil parse UserModel Peserta Eksternal', () {
      final json = {
        'id': 20,
        'name': 'Dina Pratiwi',
        'email': 'dina@gmail.com',
        'role': 'user',
        'account_type': 'external',
        'institution_name': 'Universitas Indonesia',
        'phone': '089876543210',
        'email_verified': true,
        'status': 'active',
      };

      final user = UserModel.fromJson(json);

      expect(user.isUmbStudent, isFalse);
      expect(user.institutionName, equals('Universitas Indonesia'));
      expect(user.academicSummary, equals('Universitas Indonesia'));
    });

    test('Mendeteksi status akun suspended & izin panitia', () {
      final user = const UserModel(
        id: 99,
        name: 'Admin Ormawa',
        email: 'admin@mercubuana.ac.id',
        role: 'admin',
        isOrganizer: true,
        status: 'suspended',
        suspensionReason: 'Pelanggaran SOP',
      );

      expect(user.isSuspended, isTrue);
      expect(user.suspensionReason, equals('Pelanggaran SOP'));
      expect(user.canScanTickets, isTrue);
    });

    test('Berhasil copyWith memperbarui data', () {
      final user = const UserModel(
        id: 1,
        name: 'Nama Lama',
        email: 'lama@test.com',
        emailVerified: false,
      );

      final updated = user.copyWith(
        name: 'Nama Baru',
        emailVerified: true,
      );

      expect(updated.name, equals('Nama Baru'));
      expect(updated.emailVerified, isTrue);
      expect(updated.email, equals('lama@test.com'));
    });
  });
}

