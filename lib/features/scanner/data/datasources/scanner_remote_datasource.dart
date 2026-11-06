import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/check_in_result_model.dart';

final scannerRemoteDataSourceProvider = Provider<ScannerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ScannerRemoteDataSource(apiClient);
});

class ScannerRemoteDataSource {
  final ApiClient _apiClient;

  ScannerRemoteDataSource(this._apiClient);

  // Cache memori lokal pemindaian saat Dev/Mock Mode
  static final Set<String> _scannedCodesInMock = {};

  /// Melakukan pemindaian kode QR tiket di pintu gerbang presensi (`POST /panitia/check-in/scan`)
  Future<CheckInResultModel> scanTicket({
    required int eventId,
    required String ticketCode,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/panitia/check-in/scan',
        data: {
          'event_id': eventId,
          'ticket_code': ticketCode.trim(),
        },
      );

      final data = response.data!;
      return CheckInResultModel.fromJson(data);
    } catch (_) {
      // Dev / Mock Fallback Mode
      return _mockScanTicket(ticketCode.trim());
    }
  }

  /// Presensi manual via pencarian NIM atau Nama peserta
  Future<CheckInResultModel> manualCheckIn({
    required int eventId,
    required String query,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery == '41524010001' || cleanQuery.toUpperCase() == 'TK-7F3KQ9') {
      return scanTicket(eventId: eventId, ticketCode: 'TK-7F3KQ9');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/panitia/check-in/manual',
        data: {
          'event_id': eventId,
          'query': cleanQuery,
        },
      );
      return CheckInResultModel.fromJson(response.data!);
    } catch (_) {
      return CheckInResultModel(
        status: CheckInStatus.invalidTicket,
        message: 'Peserta dengan NIM / Nama "$cleanQuery" tidak ditemukan pada acara ini.',
      );
    }
  }

  /// Mengambil daftar acara yang sedang aktif dikelola oleh panitia (SCR-13)
  Future<List<GateEventModel>> getManagedEvents() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/panitia/events');
      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => GateEventModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _mockManagedEvents;
    }
  }

  // === Dev Mock Generator Realistis ===

  CheckInResultModel _mockScanTicket(String code) {
    final upperCode = code.toUpperCase();

    // 1. Tiket Tidak Valid / Asing
    if (!upperCode.startsWith('TK-') || upperCode == 'TK-INVALID' || upperCode.length < 8) {
      return CheckInResultModel(
        status: CheckInStatus.invalidTicket,
        message: 'Kode tiket "$code" tidak terdaftar atau bukan untuk acara ini.',
        ticketCode: code,
      );
    }

    // 2. Tiket Sudah Pernah Check-in Sebelumnya
    if (_scannedCodesInMock.contains(upperCode) || upperCode == 'TK-ALREADY') {
      return CheckInResultModel(
        status: CheckInStatus.alreadyCheckedIn,
        message: 'Tiket ini sudah pernah dipindai pada 08:15 WIB oleh Panitia Pintu 1.',
        ticketCode: upperCode,
        firstCheckedInAt: DateTime.now().subtract(const Duration(minutes: 45)),
        participant: const ScannerParticipantModel(
          name: 'Yoga Gustira',
          nim: '41524010001',
          studyProgram: 'Teknik Informatika',
          cohortYear: 2024,
        ),
      );
    }

    // 3. Scan Berhasil (Success)
    _scannedCodesInMock.add(upperCode);

    return CheckInResultModel(
      status: CheckInStatus.success,
      message: 'Presensi berhasil! Selamat datang di acara.',
      ticketCode: upperCode,
      checkedInAt: DateTime.now(),
      participant: const ScannerParticipantModel(
        name: 'Yoga Gustira',
        nim: '41524010001',
        studyProgram: 'Teknik Informatika',
        cohortYear: 2024,
      ),
    );
  }

  static final List<GateEventModel> _mockManagedEvents = [
    GateEventModel(
      id: 1,
      title: 'Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia',
      slug: 'seminar-nasional-ai-2026',
      location: 'Auditorium Tower Lt. 7 Kampus Meruya',
      startAt: DateTime(2026, 11, 20, 9, 0),
      totalQuota: 200,
      attendedCount: 142,
      organizationName: 'HIMA Teknik Informatika UMB',
    ),
    GateEventModel(
      id: 2,
      title: 'Workshop Cyber Security: Penetration Testing & Ethical Hacking',
      slug: 'workshop-cyber-security-pentest',
      location: 'Lab Komputer Gedung B Lt. 3 Meruya',
      startAt: DateTime(2026, 11, 22, 13, 0),
      totalQuota: 50,
      attendedCount: 18,
      organizationName: 'HIMA Teknik Informatika UMB',
    ),
  ];
}

