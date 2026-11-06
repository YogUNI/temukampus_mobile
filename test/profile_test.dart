import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('Profile & Student Identity Unit Tests', () {
    test('Mahasiswa UMB biasa memiliki identitas resmi dan tidak memiliki izin scanner', () {
      final student = UserModel(
        id: 1,
        name: 'Yoga Pratama',
        email: 'yoga@mercubuana.ac.id',
        role: 'user',
        accountType: 'umb',
        nim: '41524010001',
        studyProgram: const StudyProgramModel(id: 1, code: '415', name: 'Teknik Informatika'),
        cohortYear: 2024,
        emailVerified: true,
        isOrganizer: false,
      );

      expect(student.isUmbStudent, isTrue);
      expect(student.canScanTickets, isFalse);
      expect(student.academicSummary, equals("Teknik Informatika '24"));
    });

    test('Panitia Ormawa memiliki izin scanner tiket hari-H (canScanTickets)', () {
      final organizer = UserModel(
        id: 2,
        name: 'Budi Panitia',
        email: 'budi.panitia@mercubuana.ac.id',
        role: 'admin',
        accountType: 'umb',
        nim: '41523010050',
        studyProgram: const StudyProgramModel(id: 1, code: '415', name: 'Teknik Informatika'),
        cohortYear: 2023,
        emailVerified: true,
        isOrganizer: true,
        managedOrganizations: const [
          ManagedOrgModel(
            id: 1,
            name: 'HIMA Teknik Informatika UMB',
            slug: 'hima-ti',
            roleInOrg: 'ketua_pelaksana',
          ),
        ],
      );

      expect(organizer.canScanTickets, isTrue);
      expect(organizer.isOrganizer, isTrue);
      expect(organizer.role, equals('admin'));
      expect(organizer.managedOrganizations.first.name, contains('HIMA'));
    });

    test('Peserta eksternal menampilkan ringkasan institusi luar', () {
      final externalUser = UserModel(
        id: 3,
        name: 'Siti Rahma',
        email: 'siti@gmail.com',
        role: 'user',
        accountType: 'external',
        institutionName: 'Universitas Indonesia',
        emailVerified: true,
      );

      expect(externalUser.isUmbStudent, isFalse);
      expect(externalUser.canScanTickets, isFalse);
      expect(externalUser.academicSummary, equals('Universitas Indonesia'));
    });
  });
}

