import '../../constants/api_endpoints.dart';
import '../../models/channel_detail_model.dart';
import '../../models/channel_member_model.dart';
import '../../models/channel_message_model.dart';
import '../../models/channel_model.dart';
import '../../models/key_envelope_model.dart';
import '../../models/pairing_request_model.dart';
import '../../models/pairing_session_model.dart';
import '../../network/api_client.dart';
import '../../utils/data_converter.dart';
import '../channel_api_client.dart';

class ChannelApiClientImpl implements ChannelApiClient {
  ChannelApiClientImpl({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _asMap(dynamic data) =>
      DataConverter.cvToMap<String, dynamic>(data) ?? <String, dynamic>{};

  List<Map<String, dynamic>> _asListOfMaps(dynamic raw) =>
      DataConverter.cvToList<Map<String, dynamic>>(
        raw,
        (item) => _asMap(item),
      );

  @override
  Future<Map<String, dynamic>> registerDeviceV2({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String publicKey,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'public_key': publicKey,
      'fcm_token': fcmToken,
    }..removeWhere((_, value) => value == null);
    return _asMap(await apiClient.post(ApiEndpoints.registerDeviceV2, body: body));
  }

  @override
  Future<void> updateFcmToken({required String fcmToken}) async {
    await apiClient.put(
      ApiEndpoints.updateFcmTokenV2,
      body: <String, dynamic>{'fcm_token': fcmToken},
    );
  }

  @override
  Future<void> updateDeviceName({required String deviceName}) async {
    await apiClient.put(
      ApiEndpoints.updateDeviceNameV2,
      body: <String, dynamic>{'device_name': deviceName},
    );
  }

  @override
  Future<Map<String, dynamic>> createChannel({
    required String name,
    required String channelId,
    required Map<String, dynamic> package,
  }) async {
    return _asMap(
      await apiClient.post(
        ApiEndpoints.createChannelV2,
        body: <String, dynamic>{
          'channel_id': channelId,
          'name': name,
          'package': package,
        },
      ),
    );
  }

  @override
  Future<List<ChannelModel>> listChannels() async {
    final data = _asMap(await apiClient.get(ApiEndpoints.listChannelsV2));
    return _asListOfMaps(data['channels']).map(ChannelModel.fromMap).toList();
  }

  @override
  Future<ChannelDetailModel> getChannelDetail({required String channelId}) async {
    final data = _asMap(
      await apiClient.get(
        ApiEndpoints.channelDetailV2,
        queryParameters: {'channel_id': channelId},
      ),
    );
    return ChannelDetailModel.fromMap(data);
  }

  @override
  Future<List<ChannelMemberModel>> getChannelMembers({
    required String channelId,
  }) async {
    final data = _asMap(
      await apiClient.get(
        ApiEndpoints.channelMembersV2,
        queryParameters: {'channel_id': channelId},
      ),
    );
    return _asListOfMaps(data['members'])
        .map(ChannelMemberModel.fromMap)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
    required Map<String, dynamic> package,
  }) async {
    return _asMap(
      await apiClient.post(
        ApiEndpoints.channelRevokeV2,
        body: <String, dynamic>{
          'channel_id': channelId,
          'revoke_device_ids': revokeDeviceIds,
          'package': package,
        },
      ),
    );
  }

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

  @override
  Future<KeyEnvelopeModel> getKeyEnvelope({
    required String channelId,
    int? epoch,
  }) async {
    final data = _asMap(
      await apiClient.get(
        ApiEndpoints.channelKeyEnvelopeV2,
        queryParameters: {
          'channel_id': channelId,
          if (epoch != null) 'epoch': '$epoch',
        },
      ),
    );
    return KeyEnvelopeModel.fromMap(data);
  }

  @override
  Future<SendMessageResultModel> sendMessageV2({
    required String channelId,
    required int requestEpoch,
    required String ciphertext,
    required String nonce,
  }) async {
    final data = _asMap(
      await apiClient.post(
        ApiEndpoints.channelMessagesV2,
        body: <String, dynamic>{
          'channel_id': channelId,
          'request_epoch': requestEpoch,
          'ciphertext': ciphertext,
          'nonce': nonce,
        },
      ),
    );
    return SendMessageResultModel.fromMap(data);
  }

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated})>
  fetchMessagesByDate({required String date, int tzOffset = 0}) async {
    final data = _asMap(
      await apiClient.get(
        ApiEndpoints.messagesByDateV2,
        queryParameters: {'date': date, 'tz_offset': '$tzOffset'},
      ),
    );
    final messages = _asListOfMaps(data['messages'])
        .map(ChannelMessageModel.fromMap)
        .toList();
    return (
      messages: messages,
      truncated: DataConverter.cvToBool(data['truncated'], false)!,
    );
  }
}
