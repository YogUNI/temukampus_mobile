import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

/// Mode tampilan katalog: Grid 2-kolom vs daftar tiket vertikal.
enum CatalogViewMode { grid, list }

class EventsCatalogState {
  final bool isLoading;
  final String? errorMessage;
  final List<EventModel> events;
  final List<CategoryModel> categories;
  final EventFilterModel filter;
  final CatalogViewMode viewMode;

  const EventsCatalogState({
    this.isLoading = false,
    this.errorMessage,
    this.events = const [],
    this.categories = const [],
    this.filter = const EventFilterModel(),
    this.viewMode = CatalogViewMode.grid,
  });

  // Convenience getters
  String get searchQuery => filter.searchQuery;
  String get selectedCategory => filter.categorySlug ?? 'all';
  String? get selectedFormat => filter.format;
  String? get selectedTag => filter.tag;
  bool get suitableForMe => filter.suitableForMeOnly;
  bool get onlyFree => filter.isFreeOnly;
  bool get onlySkp => filter.isSkpOnly;
  int? get maxPrice => filter.maxPrice;
  List<String> get organizationSlugs => filter.organizationSlugs;

  bool get isEmpty => !isLoading && errorMessage == null && events.isEmpty;
  bool get hasActiveFilter => filter.hasActiveFilter;

  EventsCatalogState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<EventModel>? events,
    List<CategoryModel>? categories,
    EventFilterModel? filter,
    CatalogViewMode? viewMode,
    String? searchQuery,
    String? selectedCategory,
    String? selectedFormat,
    String? selectedTag,
    bool? suitableForMe,
    bool? onlyFree,
    bool? onlySkp,
    int? maxPrice,
    List<String>? organizationSlugs,
    bool clearFormat = false,
    bool clearTag = false,
    bool clearMaxPrice = false,
  }) {
    EventFilterModel updatedFilter = filter ?? this.filter;

    if (searchQuery != null ||
        selectedCategory != null ||
        selectedFormat != null ||
        selectedTag != null ||
        suitableForMe != null ||
        onlyFree != null ||
        onlySkp != null ||
        maxPrice != null ||
        organizationSlugs != null ||
        clearFormat ||
        clearTag ||
        clearMaxPrice) {
      updatedFilter = updatedFilter.copyWith(
        searchQuery: searchQuery,
        categorySlug: selectedCategory == 'all' ? null : (selectedCategory ?? updatedFilter.categorySlug),
        format: selectedFormat,
        tag: selectedTag,
        suitableForMeOnly: suitableForMe,
        isFreeOnly: onlyFree,
        isSkpOnly: onlySkp,
        maxPrice: maxPrice,
        organizationSlugs: organizationSlugs,
        clearFormat: clearFormat,
        clearTag: clearTag,
        clearCategory: selectedCategory == 'all',
        clearMaxPrice: clearMaxPrice,
      );
    }

    return EventsCatalogState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      events: events ?? this.events,
      categories: categories ?? this.categories,
      filter: updatedFilter,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

final eventsCatalogControllerProvider =
    StateNotifierProvider<EventsCatalogController, EventsCatalogState>((ref) {
  final repository = ref.watch(eventsRepositoryProvider);
  return EventsCatalogController(repository);
});

class EventsCatalogController extends StateNotifier<EventsCatalogState> {
  final EventsRepository _repository;

  EventsCatalogController(this._repository) : super(const EventsCatalogState()) {
    init();
  }

  Future<void> init() async {
    await fetchCategories();
    await fetchEvents();
  }

  Future<void> fetchCategories() async {
    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(categories: categories);
    } catch (_) {}
  }

  Future<void> fetchEvents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      var events = await _repository.getEvents(filterModel: state.filter);

      // Filter sisi klien tambahan yang belum tersedia di API katalog.
      if (state.filter.isFreeOnly) {
        events = events.where((e) => e.isFree).toList();
      }
      if (state.filter.isSkpOnly) {
        events = events.where((e) => e.hasSkp).toList();
      }
      final maxPrice = state.filter.maxPrice;
      if (maxPrice != null) {
        events = events
            .where((e) => e.isFree || e.price <= maxPrice)
            .toList();
      }
      if (state.filter.organizationSlugs.isNotEmpty) {
        events = events
            .where((e) => state.filter.organizationSlugs.contains(e.organization.slug))
            .toList();
      }

      state = state.copyWith(isLoading: false, events: events);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat katalog acara. Silakan periksa jaringan Anda.',
      );
    }
  }

  void setSearchQuery(String query) {
    if (state.filter.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchEvents();
  }

  void setCategory(String categorySlug) {
    if (state.selectedCategory == categorySlug) return;
    state = state.copyWith(selectedCategory: categorySlug);
    fetchEvents();
  }

  void setQuickFilterTag(String tag) {
    switch (tag) {
      case 'Semua':
        state = state.copyWith(
          selectedCategory: 'all',
          onlyFree: false,
          onlySkp: false,
          suitableForMe: false,
          clearFormat: true,
          clearTag: true,
          clearMaxPrice: true,
          organizationSlugs: const [],
        );
        break;
      case 'Gratis':
        state = state.copyWith(onlyFree: !state.onlyFree);
        break;
      case 'Seminar':
        state = state.copyWith(selectedCategory: 'akademik');
        break;
      case 'Ber-SKP':
        state = state.copyWith(onlySkp: !state.onlySkp);
        break;
      case 'Workshop':
        state = state.copyWith(selectedTag: 'workshop');
        break;
      case 'Cocok untuk Saya':
        state = state.copyWith(suitableForMe: !state.suitableForMe);
        break;
    }
    fetchEvents();
  }

  void applyAdvancedFilters({
    required String? format,
    required bool onlyFree,
    required bool onlySkp,
    required bool suitableForMe,
    int? maxPrice,
    List<String> organizationSlugs = const [],
  }) {
    state = state.copyWith(
      selectedFormat: format,
      clearFormat: format == null,
      onlyFree: onlyFree,
      onlySkp: onlySkp,
      suitableForMe: suitableForMe,
      maxPrice: maxPrice,
      organizationSlugs: organizationSlugs,
      clearMaxPrice: maxPrice == null,
    );
    fetchEvents();
  }

  /// Beralih tampilan Grid ⇄ List (bertahan selama sesi katalog).
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == CatalogViewMode.grid
          ? CatalogViewMode.list
          : CatalogViewMode.grid,
    );
  }

  void resetFilters() {
    state = state.copyWith(
      selectedCategory: 'all',
      clearFormat: true,
      clearTag: true,
      clearMaxPrice: true,
      organizationSlugs: const [],
      onlyFree: false,
      onlySkp: false,
      suitableForMe: false,
      searchQuery: '',
    );
    fetchEvents();
  }
}
