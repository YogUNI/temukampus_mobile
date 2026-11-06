import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/scanner_remote_datasource.dart';
import '../models/check_in_result_model.dart';

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  final remoteDataSource = ref.watch(scannerRemoteDataSourceProvider);
  return ScannerRepository(remoteDataSource);
});

class ScannerRepository {
  final ScannerRemoteDataSource _remoteDataSource;

  ScannerRepository(this._remoteDataSource);

  Future<CheckInResultModel> scanTicket({
    required int eventId,
    required String ticketCode,
  }) async {
    return await _remoteDataSource.scanTicket(
      eventId: eventId,
      ticketCode: ticketCode,
    );
  }

  Future<CheckInResultModel> manualCheckIn({
    required int eventId,
    required String query,
  }) async {
    return await _remoteDataSource.manualCheckIn(
      eventId: eventId,
      query: query,
    );
  }

  Future<List<GateEventModel>> getManagedEvents() async {
    return await _remoteDataSource.getManagedEvents();
  }
}

