import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';
import '../models/request_history_result.dart';

/// Service API Ghép đôi (BE: PairingV2Controller, API spec §5).
abstract class PairingApiService {
  Future<PairingSessionModel> createPairingSession({
    required String channelId,
  });

  Future<List<PairingRequestModel>> listMyRequests();

  Future<List<PairingRequestModel>> listChannelRequests({
    required String channelId,
    String status = 'PENDING',
  });

  /// Request đã xử lý (APPROVED / REJECTED / CANCELLED), phân trang theo [before].
  Future<RequestHistoryResult> listRequestHistory({
    required String channelId,
    String? before,
    int limit = 30,
  });

  Future<Map<String, dynamic>> approvePairingRequest({
    required String requestId,
    required Map<String, dynamic> package,
  });

  Future<void> rejectPairingRequest({required String requestId});

  Future<void> cancelPairingRequest({required String requestId});
}
