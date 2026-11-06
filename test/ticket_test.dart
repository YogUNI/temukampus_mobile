import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/tickets/data/datasources/tickets_remote_datasource.dart';
import 'package:temukampus_mobile/features/tickets/data/models/ticket_model.dart';
import 'package:temukampus_mobile/features/tickets/data/repositories/tickets_repository.dart';
import 'package:temukampus_mobile/features/tickets/presentation/controllers/tickets_controller.dart';
import 'package:temukampus_mobile/features/tickets/presentation/controllers/ticket_detail_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TicketModel Unit & BR-13 Security Tests', () {
    test('BR-13: Akses link WA & Meeting HANYA terbuka jika status confirmed', () {
      final jsonConfirmed = {
        'ticket_code': 'TK-7F3KQ9',
        'status': 'confirmed',
        'participant': {'name': 'Yoga'},
        'event': {
          'title': 'Seminar AI',
          'slug': 'seminar-ai',
          'start_at': '2026-11-20T09:00:00Z',
          'end_at': '2026-11-20T12:00:00Z',
          'location': 'Auditorium Tower',
        },
        'unlocked_access': {
          'can_access_links': true,
          'wa_group_url': 'https://chat.whatsapp.com/secret-group',
          'meeting_url': 'https://zoom.us/j/123456',
        },
      };

      final ticketConfirmed = TicketModel.fromJson(jsonConfirmed);
      expect(ticketConfirmed.isConfirmed, isTrue);
      expect(ticketConfirmed.unlockedAccess.canAccessLinks, isTrue);
      expect(ticketConfirmed.unlockedAccess.waGroupUrl, isNotNull);
      expect(ticketConfirmed.unlockedAccess.meetingUrl, isNotNull);

      // Status pending_verification
      final jsonPending = {
        'ticket_code': 'TK-8K2MN4',
        'status': 'pending_verification',
        'participant': {'name': 'Yoga'},
        'event': {
          'title': 'Workshop Cyber',
          'slug': 'workshop-cyber',
          'start_at': '2026-11-22T09:00:00Z',
          'end_at': '2026-11-22T12:00:00Z',
          'location': 'Auditorium Tower',
        },
        'unlocked_access': {
          'can_access_links': true,
          'wa_group_url': 'https://chat.whatsapp.com/secret-group',
          'meeting_url': 'https://zoom.us/j/123456',
        },
      };

      final ticketPending = TicketModel.fromJson(jsonPending);
      expect(ticketPending.isPending, isTrue);
      // BR-13 Wajib null jika status belum confirmed
      expect(ticketPending.unlockedAccess.canAccessLinks, isFalse);
      expect(ticketPending.unlockedAccess.waGroupUrl, isNull);
      expect(ticketPending.unlockedAccess.meetingUrl, isNull);
    });

    test('Status needs_revision membaca revisionNotes dengan baik', () {
      final jsonRevision = {
        'ticket_code': 'TK-3P9QL1',
        'status': 'needs_revision',
        'revision_notes': 'Bukti transfer terpotong.',
        'participant': {'name': 'Yoga'},
        'event': {
          'title': 'Lomba UI/UX',
          'slug': 'lomba-uiux',
          'start_at': '2026-12-01T09:00:00Z',
          'end_at': '2026-12-01T16:00:00Z',
          'location': 'Online',
        },
      };

      final ticket = TicketModel.fromJson(jsonRevision);
      expect(ticket.isNeedsRevision, isTrue);
      expect(ticket.revisionNotes, equals('Bukti transfer terpotong.'));
      expect(ticket.statusLabel, equals('Perlu Revisi'));
    });
  });

  group('TicketsController State Tests', () {
    late TicketsController controller;
    late TicketsRepository repository;

    setUp(() {
      final apiClient = ApiClient(Dio());
      final remoteDataSource = TicketsRemoteDataSource(apiClient);
      repository = TicketsRepository(remoteDataSource);
      controller = TicketsController(repository);
    });

    test('Memuat tiket tab Akan Datang (upcoming) secara default', () async {
      await controller.fetchTickets();

      expect(controller.state.activeTab, equals('upcoming'));
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.tickets.isNotEmpty, isTrue);
      expect(controller.state.tickets.every((t) => t.isConfirmed), isTrue);
    });

    test('Ganti tab ke verifikasi (pending)', () async {
      controller.changeTab('pending');
      await controller.fetchTickets();

      expect(controller.state.activeTab, equals('pending'));
      expect(controller.state.tickets.every((t) => t.isPending || t.isNeedsRevision), isTrue);
    });
  });

  group('TicketDetailController State Tests', () {
    late TicketDetailController controller;
    late TicketsRepository repository;

    setUp(() {
      final apiClient = ApiClient(Dio());
      final remoteDataSource = TicketsRemoteDataSource(apiClient);
      repository = TicketsRepository(remoteDataSource);
      controller = TicketDetailController(repository, 'TK-7F3KQ9');
    });

    test('Memuat rincian tiket TK-7F3KQ9', () async {
      await controller.loadDetail();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.ticket, isNotNull);
      expect(controller.state.ticket!.ticketCode, equals('TK-7F3KQ9'));
      expect(controller.state.ticket!.unlockedAccess.canAccessLinks, isTrue);
    });

    test('Batalkan tiket memperbarui status menjadi cancelled', () async {
      await controller.loadDetail();
      final success = await controller.cancelTicket();

      expect(success, isTrue);
      expect(controller.state.ticket!.isCancelled, isTrue);
      expect(controller.state.ticket!.statusLabel, equals('Dibatalkan'));
    });
  });
}

