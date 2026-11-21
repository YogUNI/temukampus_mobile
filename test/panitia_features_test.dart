import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/core/utils/formatters.dart';
import 'package:temukampus_mobile/features/panitia/data/datasources/panitia_remote_datasource.dart';
import 'package:temukampus_mobile/features/panitia/data/models/panitia_models.dart';
import 'package:temukampus_mobile/features/panitia/presentation/screens/panitia_event_wizard_screen.dart';
import 'package:temukampus_mobile/features/panitia/presentation/screens/panitia_home_screen.dart';
import 'package:temukampus_mobile/features/panitia/presentation/screens/panitia_members_screen.dart';
import 'package:temukampus_mobile/features/panitia/presentation/screens/panitia_organization_screen.dart';
import 'package:temukampus_mobile/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:temukampus_mobile/features/scanner/data/models/check_in_result_model.dart';

class MockPanitiaDataSource extends PanitiaRemoteDataSource {
  MockPanitiaDataSource() : super(ApiClient(Dio()));

  @override
  Future<PanitiaDashboardModel> dashboard() async {
    return const PanitiaDashboardModel(
      eventsTotal: 3,
      registrationsActive: 15,
      pendingVerification: 2,
      confirmed: 10,
      attended: 5,
      confirmedAmount: 500000,
      attendanceRate: 50.0,
    );
  }

  @override
  Future<PanitiaEventMetaModel> getEventsMeta() async {
    return const PanitiaEventMetaModel(
      categories: [
        PanitiaMetaItem(id: 1, name: 'Seminar', slug: 'seminar'),
        PanitiaMetaItem(id: 2, name: 'Workshop', slug: 'workshop'),
      ],
      faculties: [
        PanitiaMetaItem(id: 10, name: 'Ilmu Komputer'),
      ],
      studyPrograms: [
        PanitiaMetaItem(id: 101, name: 'Teknik Informatika', facultyId: 10),
      ],
    );
  }

  @override
  Future<PanitiaOrganizationModel> getOrganization() async {
    return const PanitiaOrganizationModel(
      id: 1,
      name: 'BEM FASILKOM UMB',
      slug: 'bem-fasilkom',
      description: 'Organisasi kemahasiswaan FASILKOM',
      email: 'bemfasilkom@mercubuana.ac.id',
      instagram: 'bemfasilkom_umb',
      status: 'active',
      faculty: 'Ilmu Komputer',
      membersCount: 4,
      eventsCount: 3,
      isOwner: true,
    );
  }

  @override
  Future<List<PanitiaMemberModel>> getMembers() async {
    return const [
      PanitiaMemberModel(
        id: 1,
        userId: 10,
        name: 'Yoga Pratama',
        email: 'yoga@mercubuana.ac.id',
        role: 'owner',
        roleLabel: 'Ketua / Pemilik',
      ),
      PanitiaMemberModel(
        id: 2,
        userId: 11,
        name: 'Siti Rahma',
        email: 'siti@mercubuana.ac.id',
        role: 'staff',
        roleLabel: 'Staf Panitia',
      ),
    ];
  }
}

class MockScannerDataSource extends ScannerRemoteDataSource {
  MockScannerDataSource() : super(ApiClient(Dio()));

  @override
  Future<List<GateEventModel>> getManagedEvents() async {
    return [
      GateEventModel(
        id: 1,
        title: 'Tech Talk AI 2026',
        slug: 'tech-talk-ai',
        location: 'Auditorium Tower',
        startAt: DateTime(2026, 11, 25),
        totalQuota: 100,
        attendedCount: 5,
        registeredCount: 15,
        organizationName: 'BEM FASILKOM UMB',
      ),
    ];
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppFormatters.initialize();
  });

  group('Panitia Hub, Wizard, Profil Ormawa & Anggota Tests', () {
    testWidgets('PanitiaHomeScreen menampilkan tombol aksi cepat lengkap', (tester) async {
      final mockPanitia = MockPanitiaDataSource();
      final mockScanner = MockScannerDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            panitiaRemoteDataSourceProvider.overrideWithValue(mockPanitia),
            scannerRemoteDataSourceProvider.overrideWithValue(mockScanner),
          ],
          child: const MaterialApp(
            home: PanitiaHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan 4 tombol aksi cepat dan FAB Buat Acara muncul
      expect(find.text('Buat Acara'), findsNWidgets(2)); // FAB dan QuickAction tile
      expect(find.text('Scan Presensi'), findsOneWidget);
      expect(find.text('Profil Ormawa'), findsOneWidget);
      expect(find.text('Anggota Tim'), findsOneWidget);

      // Memastikan kartu acara muncul dengan tombol Ubah Acara
      expect(find.text('Tech Talk AI 2026'), findsOneWidget);
      expect(find.byTooltip('Ubah Acara'), findsOneWidget);
    });

    testWidgets('PanitiaEventWizardScreen menampilkan form 4-langkah dan navigasi step', (tester) async {
      final mockPanitia = MockPanitiaDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            panitiaRemoteDataSourceProvider.overrideWithValue(mockPanitia),
          ],
          child: const MaterialApp(
            home: PanitiaEventWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Info & Poster
      expect(find.text('Info & Poster'), findsOneWidget);
      expect(find.text('Jadwal & Lokasi'), findsOneWidget);
      expect(find.text('Sasaran & Kuota'), findsOneWidget);
      expect(find.text('Biaya & Tiket'), findsOneWidget);
      expect(find.text('Poster Acara (Rasio 4:5)'), findsOneWidget);
      expect(find.text('Judul Acara *'), findsOneWidget);
      expect(find.text('Kategori Acara *', skipOffstage: false), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });

    testWidgets('PanitiaOrganizationScreen menampilkan data organisasi & tombol aksi', (tester) async {
      final mockPanitia = MockPanitiaDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            panitiaRemoteDataSourceProvider.overrideWithValue(mockPanitia),
          ],
          child: const MaterialApp(
            home: PanitiaOrganizationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('BEM FASILKOM UMB'), findsWidgets);
      expect(find.text('Organisasi Aktif'), findsOneWidget);
      expect(find.text('Total Acara'), findsOneWidget);
      expect(find.text('Anggota Panitia'), findsOneWidget);
      expect(
        find.text('Simpan Perubahan Profil', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('PanitiaMembersScreen menampilkan daftar staf dan ketua', (tester) async {
      final mockPanitia = MockPanitiaDataSource();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            panitiaRemoteDataSourceProvider.overrideWithValue(mockPanitia),
          ],
          child: const MaterialApp(
            home: PanitiaMembersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Yoga Pratama'), findsOneWidget);
      expect(find.text('Ketua / Pemilik'), findsOneWidget);
      expect(find.text('Siti Rahma'), findsOneWidget);
      expect(find.text('Staf Panitia'), findsOneWidget);
    });
  });
}
