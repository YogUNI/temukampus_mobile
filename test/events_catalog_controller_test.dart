import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/events/data/datasources/events_remote_datasource.dart';
import 'package:temukampus_mobile/features/events/data/repositories/events_repository.dart';
import 'package:temukampus_mobile/features/events/presentation/controllers/events_catalog_controller.dart';

void main() {
  late EventsCatalogController controller;
  late EventsRepository repository;

  setUp(() {
    final apiClient = ApiClient(Dio());
    final remoteDataSource = EventsRemoteDataSource(apiClient);
    repository = EventsRepository(remoteDataSource);
    controller = EventsCatalogController(repository);
  });

  group('EventsCatalogController State Tests', () {
    test('Inisialisasi memuat kategori dan daftar acara mock', () async {
      await controller.init();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.events.isNotEmpty, isTrue);
      expect(controller.state.categories.isNotEmpty, isTrue);
    });

    test('Pencarian kata kunci menyaring acara yang relevan', () async {
      await controller.init();

      controller.setSearchQuery('Cyber');
      await controller.fetchEvents();

      expect(controller.state.searchQuery, equals('Cyber'));
      expect(
        controller.state.events.every((e) =>
            e.title.toLowerCase().contains('cyber') ||
            e.summary.toLowerCase().contains('cyber')),
        isTrue,
      );
    });

    test('Filter cepat Gratis hanya menampilkan acara gratis', () async {
      await controller.init();

      controller.setQuickFilterTag('Gratis');
      await controller.fetchEvents();

      expect(controller.state.onlyFree, isTrue);
      expect(controller.state.events.every((e) => e.isFree), isTrue);
    });

    test('Reset filter mengembalikan parameter ke kondisi awal', () async {
      await controller.init();

      controller.setQuickFilterTag('Gratis');
      controller.setSearchQuery('Cyber');
      expect(controller.state.hasActiveFilter, isTrue);

      controller.resetFilters();
      expect(controller.state.hasActiveFilter, isFalse);
      expect(controller.state.searchQuery, isEmpty);
    });
  });
}
