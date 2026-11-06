import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/events_remote_datasource.dart';
import '../models/event_model.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final remoteDataSource = ref.watch(eventsRemoteDataSourceProvider);
  return EventsRepository(remoteDataSource);
});

class EventsRepository {
  final EventsRemoteDataSource _remoteDataSource;

  EventsRepository(this._remoteDataSource);

  Future<List<EventModel>> getEvents({
    String? search,
    String? category,
    String? format,
    String? tag,
    bool? suitableForMe,
    int page = 1,
  }) async {
    return await _remoteDataSource.getEvents(
      search: search,
      category: category,
      format: format,
      tag: tag,
      suitableForMe: suitableForMe,
      page: page,
    );
  }

  Future<EventDetailModel> getEventDetail(String slug) async {
    return await _remoteDataSource.getEventDetail(slug);
  }

  Future<EligibilityResultModel> checkEligibility(String slug) async {
    return await _remoteDataSource.checkEligibility(slug);
  }

  Future<List<EventCategoryModel>> getCategories() async {
    return await _remoteDataSource.getCategories();
  }
}
