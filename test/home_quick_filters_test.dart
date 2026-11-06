import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/controllers/events_catalog_controller.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/home_quick_filters.dart';

EventsCatalogState _state(EventFilterModel filter) =>
    EventsCatalogState(filter: filter);

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

    test('kategori akademik & folder workshop dipetakan ke chip masing-masing',
        () {
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(categorySlug: 'akademik')),
        ),
        {2},
      );
      expect(
        HomeQuickFilters.activeIndexes(
          _state(const EventFilterModel(tag: 'workshop')),
        ),
        {4},
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
}
