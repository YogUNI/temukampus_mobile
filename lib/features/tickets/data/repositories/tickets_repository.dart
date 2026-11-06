import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/image_compressor.dart';
import '../datasources/tickets_remote_datasource.dart';
import '../models/ticket_model.dart';

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  final remoteDataSource = ref.watch(ticketsRemoteDataSourceProvider);
  return TicketsRepository(remoteDataSource);
});

class TicketsRepository {
  final TicketsRemoteDataSource _remoteDataSource;

  TicketsRepository(this._remoteDataSource);

  Future<List<TicketModel>> getTickets({String tab = 'upcoming'}) async {
    return await _remoteDataSource.getTickets(tab: tab);
  }

  Future<TicketModel> getTicketDetail(String ticketCode) async {
    return await _remoteDataSource.getTicketDetail(ticketCode);
  }

  Future<String> cancelTicket(String ticketCode) async {
    return await _remoteDataSource.cancelTicket(ticketCode);
  }

  Future<String> resubmitProof({
    required String ticketCode,
    required PickedImageData proofData,
    void Function(int sent, int total)? onProgress,
  }) async {
    return await _remoteDataSource.resubmitProof(
      ticketCode: ticketCode,
      proofData: proofData,
      onProgress: onProgress,
    );
  }
}

