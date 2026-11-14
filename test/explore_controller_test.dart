import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/datasources/events_remote_datasource.dart';
import 'package:temukampus_mobile/features/events/data/repositories/events_repository.dart';
import 'package:temukampus_mobile/features/events/presentation/controllers/events_catalog_controller.dart';

import 'helpers/fake_api.dart';

FakeApiAdapter buildAdapter() => FakeApiAdapter([
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

  group('EventsCatalogController Tampilan & Filter Lanjutan', () {
    test('toggleViewMode beralih Grid ⇄ List', () async {
      await controller.init();
      expect(controller.state.viewMode, CatalogViewMode.grid);

      controller.toggleViewMode();
      expect(controller.state.viewMode, CatalogViewMode.list);

      controller.toggleViewMode();
      expect(controller.state.viewMode, CatalogViewMode.grid);
    });

    test('maxPrice menyaring acara berbayar di atas batas', () async {
      await controller.init();
      final allCount = controller.state.events.length;
      expect(allCount, greaterThan(1));

      controller.applyAdvancedFilters(
        format: controller.state.selectedFormat,
        onlyFree: false,
        onlySkp: false,
        suitableForMe: false,
        maxPrice: 30000,
        organizationSlugs: const [],
      );
      await controller.fetchEvents();

      expect(controller.state.maxPrice, 30000);
      expect(controller.state.events.length, lessThan(allCount));
      expect(
        controller.state.events.every((e) => e.isFree || e.price <= 30000),
        isTrue,
      );
    });

    test('organizationSlugs menyaring hanya acara ormawa terpilih', () async {
      await controller.init();
      final targetOrg = controller.state.events.first.organization;

      controller.applyAdvancedFilters(
        format: controller.state.selectedFormat,
        onlyFree: false,
        onlySkp: false,
        suitableForMe: false,
        organizationSlugs: [targetOrg.slug],
      );
      await controller.fetchEvents();

      expect(controller.state.organizationSlugs, [targetOrg.slug]);
      expect(controller.state.events, isNotEmpty);
      expect(
        controller.state.events.every((e) => e.organization.slug == targetOrg.slug),
        isTrue,
      );
    });

    test('format offline dikirim ke server sebagai query format', () async {
      await controller.init();

      controller.applyAdvancedFilters(
        format: 'offline',
        onlyFree: false,
        onlySkp: false,
        suitableForMe: false,
        organizationSlugs: const [],
      );
      await controller.fetchEvents();

      expect(controller.state.selectedFormat, 'offline');
      expect(controller.state.events.every((e) => e.format == 'offline'), isTrue);
    });

    test('resetFilters menghapus maxPrice & ormawa', () async {
      await controller.init();
      final targetOrg = controller.state.events.first.organization;

      controller.applyAdvancedFilters(
        format: 'offline',
        onlyFree: false,
        onlySkp: false,
        suitableForMe: false,
        maxPrice: 250000,
        organizationSlugs: [targetOrg.slug],
      );
      expect(controller.state.hasActiveFilter, isTrue);

      controller.resetFilters();

      expect(controller.state.hasActiveFilter, isFalse);
      expect(controller.state.maxPrice, isNull);
      expect(controller.state.organizationSlugs, isEmpty);
    });

    test('setQuickFilterTag Semua juga membersihkan filter lanjutan', () async {
      await controller.init();
      final targetOrg = controller.state.events.first.organization;

      controller.applyAdvancedFilters(
        format: null,
        onlyFree: true,
        onlySkp: false,
        suitableForMe: false,
        maxPrice: 100000,
        organizationSlugs: [targetOrg.slug],
      );
      expect(controller.state.hasActiveFilter, isTrue);

      controller.setQuickFilterTag('Semua');
      await controller.fetchEvents();

      expect(controller.state.hasActiveFilter, isFalse);
    });
  });
}
