import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';

/// Service API Ghép đôi (BE: PairingV2Controller, API spec §5).
abstract class PairingApiService {
  Future<PairingSessionModel> createPairingSession({
    required String channelId,
  });

  Future<ClaimRequestResultModel> claimPairingRequest({
    required String sessionId,
    required String pairingToken,
    required String deviceName,
  });

  Future<List<PairingRequestModel>> listMyRequests();

  Future<List<PairingRequestModel>> listChannelRequests({
    required String channelId,
    String status = 'PENDING',
  });

  Future<Map<String, dynamic>> approvePairingRequest({
    required String requestId,
    required Map<String, dynamic> package,
  });

  Future<void> rejectPairingRequest({required String requestId});

  Future<void> cancelPairingRequest({required String requestId});
}
