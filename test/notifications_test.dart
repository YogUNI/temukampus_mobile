import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:temukampus_mobile/features/notifications/data/models/app_notification_model.dart';
import 'package:temukampus_mobile/features/notifications/data/repositories/notifications_repository.dart';

import 'helpers/fake_api.dart';

/// Notifikasi in-app: fixture direkam dari API sungguhan setelah action
/// `ApproveRegistration` (kelas notifikasi nyata, bukan data karangan).
FakeApiAdapter buildAdapter({Map<String, dynamic>? listBody, int listStatus = 200}) {
  return FakeApiAdapter([
    FakeRoute(
      method: 'GET',
      path: '/notifications',
      query: {'filter': 'unread'},
      body: apiFixture('notifications_empty.json'),
    ),
    FakeRoute(
      method: 'GET',
      path: '/notifications',
      body: listBody ?? apiFixture('notifications_index.json'),
      status: listStatus,
    ),
    FakeRoute(method: 'GET', path: '/notifications/unread-count', body: apiFixture('notifications_unread.json')),
    FakeRoute(
      method: 'POST',
      path: RegExp(r'^/notifications/[^/]+/read$'),
      body: apiFixture('notification_read.json'),
    ),
    FakeRoute(
      method: 'POST',
      path: '/notifications/read-all',
      body: {
        'success': true,
        'message': 'Semua notifikasi ditandai sudah dibaca.',
        'data': {'unread_count': 0},
      },
    ),
    FakeRoute(
      method: 'DELETE',
      path: RegExp(r'^/notifications/[^/]+$'),
      body: {
        'success': true,
        'message': 'Notifikasi dihapus.',
        'data': {'unread_count': 0},
      },
    ),
  ]);
}

void main() {
  group('AppNotificationModel', () {
    test('membaca payload notifikasi nyata dari backend', () {
      final raw = (apiFixture('notifications_index.json')['data'] as List<dynamic>).first
          as Map<String, dynamic>;

      final model = AppNotificationModel.fromJson(raw);

      expect(model.title, equals('Pendaftaran terkonfirmasi'));
      expect(model.category, equals('registration'));
      expect(model.isRead, isFalse);
      expect(model.actionRoute, startsWith('/tickets/'));
      expect(model.actionLabel, isNotNull);
    });

    test('label waktu relatif dalam bahasa Indonesia', () {
      final now = DateTime.now();

      expect(
        AppNotificationModel(id: '1', title: 't', message: 'm', createdAt: now)
            .relativeTime,
        equals('Baru saja'),
      );
      expect(
        AppNotificationModel(
          id: '2',
          title: 't',
          message: 'm',
          createdAt: now.subtract(const Duration(hours: 3)),
        ).relativeTime,
        equals('3 jam lalu'),
      );
      expect(
        AppNotificationModel(
          id: '3',
          title: 't',
          message: 'm',
          createdAt: now.subtract(const Duration(days: 2)),
        ).relativeTime,
        equals('2 hari lalu'),
      );
    });
  });

  group('NotificationsController', () {
    late NotificationsController controller;
    late FakeApiAdapter adapter;

    void build({Map<String, dynamic>? listBody, int listStatus = 200}) {
      adapter = buildAdapter(listBody: listBody, listStatus: listStatus);
      final repository = NotificationsRepository(
        NotificationsRemoteDataSource(fakeApiClient(adapter)),
      );
      controller = NotificationsController(repository);
    }

    setUp(build);

    test('memuat daftar + jumlah belum dibaca', () async {
      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.items, isNotEmpty);
      expect(controller.state.unreadCount, equals(1));
      expect(adapter.requests, contains('GET /notifications'));
    });

    test('menandai dibaca mengubah state dan memanggil API', () async {
      await controller.load();
      final item = controller.state.items.first;

      await controller.markRead(item);

      expect(controller.state.items.first.isRead, isTrue);
      expect(controller.state.unreadCount, equals(0));
      expect(adapter.requests.any((r) => r.contains('/read')), isTrue);
    });

    test('tandai semua dibaca mengosongkan badge', () async {
      await controller.load();

      await controller.markAllRead();

      expect(controller.state.unreadCount, equals(0));
      expect(controller.state.items.every((e) => e.isRead), isTrue);
      expect(adapter.requests, contains('POST /notifications/read-all'));
    });

    test('hapus menghilangkan item dari daftar', () async {
      await controller.load();
      final item = controller.state.items.first;

      await controller.delete(item);

      expect(controller.state.items.any((e) => e.id == item.id), isFalse);
    });

    test('kegagalan API menghasilkan pesan error, bukan daftar kosong palsu', () async {
      build(listStatus: 500, listBody: {'message': 'Server bermasalah.'});

      await controller.load();

      expect(controller.state.items, isEmpty);
      expect(controller.state.errorMessage, isNotNull);
    });
  });
}
