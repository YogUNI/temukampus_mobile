import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/events/data/datasources/events_remote_datasource.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/data/repositories/events_repository.dart';
import 'package:temukampus_mobile/features/events/presentation/controllers/events_catalog_controller.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/home_quick_filters.dart';

import 'helpers/fake_api.dart';

/// Chip cepat Beranda: slug kategori yang benar + tidak berbohong soal filter.
///
/// Regresi nyata: chip "Seminar" mengirim `category=akademik` dan chip
/// "Workshop" mengirim `tag=workshop`. Keduanya tidak ada di API katalog
/// (`categories`: seminar, workshop, lomba, pelatihan, …; tanpa filter `tag`),
/// sehingga katalog selalu kosong padahal chip tampak seperti tanpa filter.
EventsCatalogState _state(EventFilterModel filter) =>
    EventsCatalogState(filter: filter);

FakeApiAdapter _buildAdapter() => FakeApiAdapter([
      FakeRoute(
        method: 'GET',
        path: '/events',
        query: {'category': 'seminar'},
        body: apiFixture('events_search.json'),
      ),
      FakeRoute(
        method: 'GET',
        path: '/events',
        query: {'category': 'workshop'},
        body: apiFixture('events_search.json'),
      ),
      FakeRoute(method: 'GET', path: '/events', body: apiFixture('events_index.json')),
      FakeRoute(method: 'GET', path: '/categories', body: apiFixture('categories.json')),
    ]);

void main() {
  group('HomeQuickFilters.activeIndexes', () {
    test('tanpa filter aktif hanya chip "Semua" yang menyala', () {
      expect(
        HomeQuickFilters.activeIndexes(_state(const EventFilterModel())),
        {0},
      );
    });

    test('filter gratis menyalakan chip Gratis', () {
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(isFreeOnly: true)),
        ),
        {1},
      );
    });

    test('filter kombinatif gratis + ber-SKP menyalakan dua chip', () {
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(isFreeOnly: true, isSkpOnly: true)),
        ),
        {1, 3},
      );
    });

    test('kategori seminar & workshop memakai slug API, bukan akademik/tag', () {
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(categorySlug: 'seminar')),
        ),
        {2},
      );
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(categorySlug: 'workshop')),
        ),
        {4},
      );
    });

    test('filter tanpa chip tidak menyalakan "Semua"', () {
      // Katalog bisa kosong karena format/tag/harga — chip "Semua" menyala
      // akan membuat pengguna mengira tidak ada filter sama sekali.
      expect(
        HomeQuickFilters.activeIndexes(_state(const EventFilterModel(format: 'online'))),
        isEmpty,
      );
      expect(
        HomeQuickFilters.activeIndexes(_state(const EventFilterModel(tag: 'workshop'))),
        isEmpty,
      );
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(categorySlug: 'seni-budaya')),
        ),
        isEmpty,
      );
    });

    test('reset filter mengembalikan chip ke "Semua"', () {
      final active = _state(const EventFilterModel(isSkpOnly: true));
      expect(HomeQuickFilters.activeIndexes(active), {3});
      expect(
        HomeQuickFilters.activeIndexes(_state(const EventFilterModel())),
        {0},
      );
    });
  });

  group('EventsCatalogController chip cepat', () {
    late EventsCatalogController controller;
    late FakeApiAdapter adapter;

    setUp(() {
      adapter = _buildAdapter();
      final repository =
          EventsRepository(EventsRemoteDataSource(fakeApiClient(adapter)));
      controller = EventsCatalogController(repository);
    });

    test('Seminar mengirim category=seminar (bukan akademik)', () async {
      await controller.init();
      adapter.requestsWithQuery.clear();

      controller.setQuickFilterTag('Seminar');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(controller.state.selectedCategory, 'seminar');
      expect(adapter.requestsWithQuery.any((r) => r.contains('category=seminar')), isTrue);
      expect(adapter.requestsWithQuery.any((r) => r.contains('akademik')), isFalse);
    });

    test('Workshop mengirim category=workshop (bukan tag)', () async {
      await controller.init();
      adapter.requestsWithQuery.clear();

      controller.setQuickFilterTag('Workshop');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(controller.state.selectedCategory, 'workshop');
      expect(controller.state.selectedTag, isNull);
      expect(adapter.requestsWithQuery.any((r) => r.contains('category=workshop')), isTrue);
      expect(adapter.requestsWithQuery.any((r) => r.contains('tag=')), isFalse);
    });

    test('Semua menghapus seluruh filter', () async {
      await controller.init();

      controller.setQuickFilterTag('Gratis');
      controller.setQuickFilterTag('Semua');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.hasActiveFilter, isFalse);
      expect(controller.state.selectedCategory, 'all');
    });
  });

  test('Beranda dan Jelajah memakai instans controller terpisah', () async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient(_buildAdapter())),
      ],
    );
    addTearDown(container.dispose);

    final home = container.read(homeCatalogControllerProvider.notifier);
    final explore = container.read(eventsCatalogControllerProvider.notifier);

    expect(identical(home, explore), isFalse);

    await Future<void>.delayed(Duration.zero);

    explore.applyAdvancedFilters(
      format: 'online',
      onlyFree: false,
      onlySkp: false,
      suitableForMe: false,
    );
    await Future<void>.delayed(Duration.zero);

    // Filter Jelajah tidak boleh menyaring Beranda.
    expect(container.read(homeCatalogControllerProvider).selectedFormat, isNull);
    expect(container.read(eventsCatalogControllerProvider).selectedFormat, 'online');
  });
}
