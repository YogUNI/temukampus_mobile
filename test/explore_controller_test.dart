import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/events/data/datasources/events_remote_datasource.dart';
import 'package:temukampus_mobile/features/events/data/repositories/events_repository.dart';
import 'package:temukampus_mobile/features/events/presentation/controllers/events_catalog_controller.dart';

void main() {
  late EventsCatalogController controller;

  setUp(() {
    final apiClient = ApiClient(Dio());
    final remoteDataSource = EventsRemoteDataSource(apiClient);
    final repository = EventsRepository(remoteDataSource);
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
        controller.state.events.every(
          (e) => e.organization.slug == targetOrg.slug,
        ),
        isTrue,
      );
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