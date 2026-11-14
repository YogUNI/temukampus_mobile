import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/datasources/events_remote_datasource.dart';
import 'package:temukampus_mobile/features/events/data/repositories/events_repository.dart';
import 'package:temukampus_mobile/features/events/presentation/controllers/events_catalog_controller.dart';

import 'helpers/fake_api.dart';

/// Rute katalog memakai fixture rekaman API v1 sungguhan; rute dengan query
/// lebih spesifik didaftarkan lebih dulu agar cocok sebelum rute umum.
FakeApiAdapter buildAdapter() => FakeApiAdapter([
      FakeRoute(
        method: 'GET',
        path: '/events',
        query: {'search': 'OASE'},
        body: apiFixture('events_search.json'),
      ),
      FakeRoute(
        method: 'GET',
        path: '/events',
        query: {'free_only': '1'},
        body: apiFixture('events_free.json'),
      ),
      FakeRoute(
        method: 'GET',
        path: '/events',
        query: {'format': 'offline'},
        body: apiFixture('events_offline.json'),
      ),
      FakeRoute(method: 'GET', path: '/events', body: apiFixture('events_index.json')),
      FakeRoute(method: 'GET', path: '/categories', body: apiFixture('categories.json')),
    ]);

void main() {
  late EventsCatalogController controller;
  late FakeApiAdapter adapter;

  setUp(() {
    adapter = buildAdapter();
    final repository = EventsRepository(EventsRemoteDataSource(fakeApiClient(adapter)));
    controller = EventsCatalogController(repository);
  });

  group('EventsCatalogController State Tests', () {
    test('Inisialisasi memuat kategori dan daftar acara dari API', () async {
      await controller.init();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.events.isNotEmpty, isTrue);
      expect(controller.state.categories.isNotEmpty, isTrue);
      expect(adapter.requests, contains('GET /events'));
      expect(adapter.requests, contains('GET /categories'));
    });

    test('Pencarian kata kunci dikirim ke server dan hasilnya dipakai', () async {
      await controller.init();

      controller.setSearchQuery('OASE');
      await controller.fetchEvents();

      expect(controller.state.searchQuery, equals('OASE'));
      expect(controller.state.events, isNotEmpty);
      expect(
        controller.state.events.every(
          (e) => e.title.toLowerCase().contains('oase') ||
              e.summary.toLowerCase().contains('oase'),
        ),
        isTrue,
      );
    });

    test('Filter cepat Gratis hanya menampilkan acara gratis', () async {
      await controller.init();

      controller.setQuickFilterTag('Gratis');
      await controller.fetchEvents();

      expect(controller.state.onlyFree, isTrue);
      expect(controller.state.events, isNotEmpty);
      expect(controller.state.events.every((e) => e.isFree), isTrue);
    });

    test('Reset filter mengembalikan parameter ke kondisi awal', () async {
      await controller.init();

      controller.setQuickFilterTag('Gratis');
      controller.setSearchQuery('OASE');
      expect(controller.state.hasActiveFilter, isTrue);

      controller.resetFilters();
      await controller.fetchEvents();

      expect(controller.state.hasActiveFilter, isFalse);
      expect(controller.state.searchQuery, isEmpty);
    });

    test('Kegagalan API menghasilkan state error, bukan data palsu', () async {
      // Tanpa rute terdaftar → adapter membalas 404.
      final broken = FakeApiAdapter(const []);
      final repository = EventsRepository(EventsRemoteDataSource(fakeApiClient(broken)));
      final brokenController = EventsCatalogController(repository);

      await brokenController.init();

      expect(brokenController.state.events, isEmpty);
      expect(brokenController.state.errorMessage, isNotNull);
      expect(brokenController.state.isLoading, isFalse);
    });
  });
}
