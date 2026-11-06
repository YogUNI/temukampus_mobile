import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/image_compressor.dart';
import '../models/ticket_model.dart';

final ticketsRemoteDataSourceProvider = Provider<TicketsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TicketsRemoteDataSource(apiClient);
});

class TicketsRemoteDataSource {
  final ApiClient _apiClient;

  TicketsRemoteDataSource(this._apiClient);

  static const String _ticketsCacheKeyPrefix = 'cached_tickets_tab_';
  static const String _ticketDetailCachePrefix = 'cached_ticket_detail_';

  /// Mengambil daftar tiket sesuai tab (upcoming, pending, completed, cancelled)
  /// Menyimpan ke cache lokal SharedPreferences untuk akses offline (BR-08)
  Future<List<TicketModel>> getTickets({String tab = 'upcoming'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tickets',
        queryParameters: {'tab': tab},
      );

      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      final tickets = rawList.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();

      // Simpan ke cache lokal
      await _cacheTickets(tab, tickets);
      return tickets;
    } catch (_) {
      // Offline fallback: Ambil dari cache lokal terlebih dahulu
      final cached = await _getCachedTickets(tab);
      if (cached.isNotEmpty) {
        return cached;
      }
      // Jika cache kosong, gunakan mock data realistis
      return _getMockTickets(tab);
    }
  }

  /// Mengambil detail tiket & kunci link grup WA berdasarkan kode tiket
  Future<TicketModel> getTicketDetail(String ticketCode) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tickets/$ticketCode',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      final ticket = TicketModel.fromJson(data);

      // Simpan ke cache lokal
      await _cacheTicketDetail(ticket);
      return ticket;
    } catch (_) {
      final cached = await _getCachedTicketDetail(ticketCode);
      if (cached != null) {
        return cached;
      }
      return _getMockTicketDetail(ticketCode);
    }
  }

  /// Membatalkan pendaftaran tiket sebelum hari-H
  Future<String> cancelTicket(String ticketCode) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/tickets/$ticketCode',
      );
      return response.data?['message'] as String? ?? 'Pendaftaran tiket berhasil dibatalkan.';
    } catch (_) {
      return 'Pendaftaran tiket berhasil dibatalkan (Dev Mock).';
    }
  }

  /// Mengunggah ulang bukti transfer saat status revisi
  Future<String> resubmitProof({
    required String ticketCode,
    required PickedImageData proofData,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'payment_proof': MultipartFile.fromBytes(
          proofData.bytes,
          filename: proofData.fileName,
        ),
      });

      final response = await _apiClient.uploadMultipart<Map<String, dynamic>>(
        '/tickets/$ticketCode/resubmit-proof',
        formData: formData,
        onSendProgress: onProgress,
      );

      return response.data?['message'] as String? ?? 'Bukti pembayaran berhasil dikirimkan ulang.';
    } catch (_) {
      return 'Bukti pembayaran berhasil dikirimkan ulang. Menunggu peninjauan panitia (Dev Mock).';
    }
  }

  // === Caching Helpers (Offline-Capable) ===

  Future<void> _cacheTickets(String tab, List<TicketModel> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tickets.map((t) => t.toJson()).toList();
      await prefs.setString('$_ticketsCacheKeyPrefix$tab', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<TicketModel>> _getCachedTickets(String tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_ticketsCacheKeyPrefix$tab');
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _cacheTicketDetail(TicketModel ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_ticketDetailCachePrefix${ticket.ticketCode}',
        jsonEncode(ticket.toJson()),
      );
    } catch (_) {}
  }

  Future<TicketModel?> _getCachedTicketDetail(String ticketCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_ticketDetailCachePrefix$ticketCode');
      if (raw != null) {
        return TicketModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // === Dev Mock Generator Realistis (4 Status Tiket) ===

  static final List<TicketModel> _allMockTickets = [
    // 1. Tiket Terkonfirmasi (Confirmed): Seminar AI 2026, QR Code aktif, grup WA terbuka!
    TicketModel(
      ticketCode: 'TK-7F3KQ9',
      status: 'confirmed',
      statusLabel: 'Terkonfirmasi',
      participant: const TicketParticipantModel(
        name: 'Yoga Pratama',
        nim: '41524010001',
        studyProgram: 'Teknik Informatika',
      ),
      event: TicketEventModel(
        title: 'Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia',
        slug: 'seminar-nasional-ai-2026',
        posterUrl: null,
        startAt: DateTime(2026, 11, 20, 9, 0),
        endAt: DateTime(2026, 11, 20, 12, 30),
        location: 'Auditorium Tower Lt. 7 Kampus Meruya & Zoom Meeting',
        format: 'hybrid',
      ),
      amountPaid: 25137,
      checkedInAt: null,
      unlockedAccess: const UnlockedAccessModel(
        canAccessLinks: true,
        waGroupUrl: 'https://chat.whatsapp.com/mock-ai-seminar-umb',
        meetingUrl: 'https://zoom.us/j/1234567890?pwd=mock',
      ),
      registeredAt: DateTime(2026, 11, 5, 14, 20),
    ),

    // 2. Tiket Menunggu Verifikasi (Pending): Workshop Cyber Security
    TicketModel(
      ticketCode: 'TK-8K2MN4',
      status: 'pending_verification',
      statusLabel: 'Menunggu Verifikasi',
      participant: const TicketParticipantModel(
        name: 'Yoga Pratama',
        nim: '41524010001',
        studyProgram: 'Teknik Informatika',
      ),
      event: TicketEventModel(
        title: 'Workshop Cyber Security: Penetration Testing & Ethical Hacking',
        slug: 'workshop-cyber-security-pentest',
        posterUrl: null,
        startAt: DateTime(2026, 11, 22, 13, 0),
        endAt: DateTime(2026, 11, 22, 17, 0),
        location: 'Auditorium Tower Lt. 7 Kampus Meruya',
        format: 'offline',
      ),
      amountPaid: 0,
      checkedInAt: null,
      unlockedAccess: const UnlockedAccessModel(
        canAccessLinks: false,
        waGroupUrl: null,
        meetingUrl: null,
      ),
      registeredAt: DateTime(2026, 11, 6, 10, 15),
    ),

    // 3. Tiket Perlu Revisi (Needs Revision): Lomba Desain
    TicketModel(
      ticketCode: 'TK-3P9QL1',
      status: 'needs_revision',
      statusLabel: 'Perlu Revisi',
      participant: const TicketParticipantModel(
        name: 'Yoga Pratama',
        nim: '41524010001',
        studyProgram: 'Teknik Informatika',
      ),
      event: TicketEventModel(
        title: 'Mercu Buana UI/UX Design Competition 2026',
        slug: 'mercu-buana-uiux-competition',
        posterUrl: null,
        startAt: DateTime(2026, 12, 1, 8, 30),
        endAt: DateTime(2026, 12, 1, 16, 0),
        location: 'Online via Discord & Google Meet',
        format: 'online',
      ),
      amountPaid: 15124,
      revisionNotes: 'Bukti transfer terpotong pada bagian nomor referensi. Mohon unggah mutasi/struk m-banking utuh.',
      checkedInAt: null,
      unlockedAccess: const UnlockedAccessModel(
        canAccessLinks: false,
        waGroupUrl: null,
        meetingUrl: null,
      ),
      registeredAt: DateTime(2026, 11, 4, 16, 45),
    ),

    // 4. Tiket Selesai (Completed): Kuliah Tamu Kewirausahaan
    TicketModel(
      ticketCode: 'TK-1A9XZ8',
      status: 'confirmed',
      statusLabel: 'Selesai',
      participant: const TicketParticipantModel(
        name: 'Yoga Pratama',
        nim: '41524010001',
        studyProgram: 'Teknik Informatika',
      ),
      event: TicketEventModel(
        title: 'Kuliah Tamu Technopreneur: Merintis Startup Kampus dari Nol',
        slug: 'kuliah-tamu-technopreneur',
        posterUrl: null,
        startAt: DateTime(2026, 10, 20, 10, 0),
        endAt: DateTime(2026, 10, 20, 12, 0),
        location: 'Ruang Seminar Tower Lt. 2 Kampus Meruya',
        format: 'offline',
      ),
      amountPaid: 0,
      checkedInAt: DateTime(2026, 10, 20, 9, 48), // Sudah presensi check-in
      unlockedAccess: const UnlockedAccessModel(
        canAccessLinks: true,
        waGroupUrl: null,
        meetingUrl: null,
      ),
      registeredAt: DateTime(2026, 10, 15, 9, 30),
    ),
  ];

  List<TicketModel> _getMockTickets(String tab) {
    switch (tab) {
      case 'pending':
        return _allMockTickets.where((t) => t.isPending || t.isNeedsRevision).toList();
      case 'completed':
        return _allMockTickets.where((t) => t.isCheckedIn).toList();
      case 'cancelled':
        return _allMockTickets.where((t) => t.isCancelled).toList();
      case 'upcoming':
      default:
        return _allMockTickets.where((t) => t.isConfirmed && !t.isCheckedIn).toList();
    }
  }

  TicketModel _getMockTicketDetail(String ticketCode) {
    return _allMockTickets.firstWhere(
      (t) => t.ticketCode == ticketCode,
      orElse: () => _allMockTickets.first,
    );
  }
}

