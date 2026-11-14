import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
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
    } on AppException {
      // Offline (BR-08): tampilkan cache lokal bila ada, selain itu biarkan
      // galat asli naik agar layar menampilkan status Error + "Coba Lagi".
      final cached = await _getCachedTickets(tab);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    } on DioException catch (e) {
      final cached = await _getCachedTickets(tab);
      if (cached.isNotEmpty) {
        return cached;
      }
      throw _asAppException(e);
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
    } on AppException {
      final cached = await _getCachedTicketDetail(ticketCode);
      if (cached != null) {
        return cached;
      }
      rethrow;
    } on DioException catch (e) {
      final cached = await _getCachedTicketDetail(ticketCode);
      if (cached != null) {
        return cached;
      }
      throw _asAppException(e);
    }
  }

  /// Membatalkan pendaftaran tiket sebelum hari-H
  Future<String> cancelTicket(String ticketCode) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        ApiEndpoints.ticketDetail(ticketCode),
      );
      return response.data?['message'] as String? ?? 'Pendaftaran tiket berhasil dibatalkan.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
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
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _asAppException(e);
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

  /// Setiap kegagalan Dio yang belum bertipe diterjemahkan ke [AppException],
  /// supaya UI selalu punya pesan bahasa Indonesia yang bisa ditampilkan.
  AppException _asAppException(DioException e) {
    final error = e.error;
    if (error is AppException) return error;

    return ServerException(
      'Tidak dapat menghubungi server TemuKampus. Periksa koneksi lalu coba lagi.',
      e.response?.statusCode,
    );
  }
}
