import '../../constants/api_endpoints.dart';
import '../../models/invite_preview_model.dart';
import '../../models/pairing_request_model.dart';
import '../../models/pairing_session_model.dart';
import '../../network/api_client.dart';
import '../../utils/data_converter.dart';
import '../pairing_api_service.dart';

class PairingApiServiceImpl implements PairingApiService {
  PairingApiServiceImpl({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _asMap(dynamic data) =>
      DataConverter.cvToMap<String, dynamic>(data) ?? <String, dynamic>{};

  List<Map<String, dynamic>> _asListOfMaps(dynamic raw) =>
      DataConverter.cvToList<Map<String, dynamic>>(
        raw,
        (item) => _asMap(item),
      );

  @override
  Future<PairingSessionModel> createPairingSession({
    required String channelId,
  }) async {
    final data = _asMap(
      await apiClient.post(
        ApiEndpoints.channelSessionsV2,
        body: <String, dynamic>{'channel_id': channelId},
      ),
    );
    return PairingSessionModel.fromMap(data);
  }

  @override
  Future<InvitePreviewModel> resolveSession({
    required String sessionId,
    required String pairingToken,
  }) async {
    final data = _asMap(
      await apiClient.post(
        ApiEndpoints.channelSessionsResolveV2,
        body: <String, dynamic>{
          'session_id': sessionId,
          'pairing_token': pairingToken,
        },
      ),
    );
    return InvitePreviewModel.fromMap(data);
  }

  @override
  Future<ClaimRequestResultModel> claimPairingRequest({
    required String sessionId,
    required String pairingToken,
    required String deviceName,
  }) async {
    final data = _asMap(
      await apiClient.post(
        ApiEndpoints.pairingClaimV2,
        body: <String, dynamic>{
          'session_id': sessionId,
          'pairing_token': pairingToken,
          'device_name': deviceName,
        },
      ),
    );
    return ClaimRequestResultModel.fromMap(data);
  }

  @override
  Future<List<PairingRequestModel>> listMyRequests() async {
    final data = _asMap(await apiClient.get(ApiEndpoints.pairingMineV2));
    return _asListOfMaps(data['requests'])
        .map(PairingRequestModel.fromMap)
        .toList();
  }

  @override
  Future<List<PairingRequestModel>> listChannelRequests({
    required String channelId,
    String status = 'PENDING',
  }) async {
    final data = _asMap(
      await apiClient.get(
        ApiEndpoints.channelRequestsV2,
        queryParameters: {'channel_id': channelId, 'status': status},
      ),
    );
    return _asListOfMaps(data['requests'])
        .map(PairingRequestModel.fromMap)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> approvePairingRequest({
    required String requestId,
    required Map<String, dynamic> package,
  }) async {
    return _asMap(
      await apiClient.post(
        ApiEndpoints.pairingApproveV2,
        body: <String, dynamic>{'request_id': requestId, 'package': package},
      ),
    );
  }

  @override
  Future<void> rejectPairingRequest({required String requestId}) async {
    await apiClient.post(
      ApiEndpoints.pairingRejectV2,
      body: <String, dynamic>{'request_id': requestId},
    );
  }

  @override
  Future<void> cancelPairingRequest({required String requestId}) async {
    await apiClient.post(
      ApiEndpoints.pairingCancelV2,
      body: <String, dynamic>{'request_id': requestId},
    );
  }
}
