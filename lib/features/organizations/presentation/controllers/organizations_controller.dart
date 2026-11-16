import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../data/datasources/organizations_remote_datasource.dart';
import '../../data/models/organization_model.dart';

/// State direktori organisasi: data, chip, filter aktif, dan status muat.
class OrganizationsState {
  final bool isLoading;
  final String? errorMessage;
  final List<OrganizationModel> items;
  final List<OrganizationGroupModel> groups;
  final int total;
  final String activeGroup;
  final String searchQuery;

  /// Jumlah seluruh organisasi aktif (chip "Semua").
  final int overallCount;

  const OrganizationsState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.groups = const [],
    this.total = 0,
    this.activeGroup = '',
    this.searchQuery = '',
    this.overallCount = 0,
  });

  bool get isEmpty => !isLoading && errorMessage == null && items.isEmpty;

  OrganizationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<OrganizationModel>? items,
    List<OrganizationGroupModel>? groups,
    int? total,
    String? activeGroup,
    String? searchQuery,
    int? overallCount,
  }) {
    return OrganizationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
      groups: groups ?? this.groups,
      total: total ?? this.total,
      activeGroup: activeGroup ?? this.activeGroup,
      searchQuery: searchQuery ?? this.searchQuery,
      overallCount: overallCount ?? this.overallCount,
    );
  }
}

class OrganizationsController extends StateNotifier<OrganizationsState> {
  final OrganizationsRemoteDataSource _dataSource;

  OrganizationsController(this._dataSource) : super(const OrganizationsState()) {
    load();
  }

  Future<void> load({String? group, String? search}) async {
    final activeGroup = group ?? state.activeGroup;
    final query = search ?? state.searchQuery;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      activeGroup: activeGroup,
      searchQuery: query,
    );

    try {
      final directory = await _dataSource.getDirectory(
        group: activeGroup,
        search: query,
      );

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        items: directory.items,
        groups: directory.groups,
        total: directory.total,
        activeGroup: directory.activeGroup,
        overallCount: directory.overallCount,
        clearError: true,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> selectGroup(String group) => load(group: group);

  Future<void> search(String query) => load(search: query);

  Future<void> retry() => load();
}

final organizationsControllerProvider =
    StateNotifierProvider<OrganizationsController, OrganizationsState>((ref) {
  return OrganizationsController(ref.watch(organizationsRemoteDataSourceProvider));
});

/// Detail satu organisasi (profil + acara mendatang + arsip).
final organizationDetailProvider =
    FutureProvider.autoDispose.family<OrganizationDetailModel, String>((ref, slug) {
  return ref.watch(organizationsRemoteDataSourceProvider).getDetail(slug);
});
