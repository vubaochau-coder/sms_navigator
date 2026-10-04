import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/data_converter.dart';
import '../models/channel_detail_model.dart';
import '../models/channel_member_model.dart';
import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/key_envelope_model.dart';
import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';

/// API Client v2 cho kiến trúc Kênh 1-to-N E2EE (SERVER_API_SPEC v1.5).
///
/// Chỉ làm một nhiệm vụ: gọi đúng endpoint v2 và map payload thô sang Model.
/// Toàn bộ logic nghiệp vụ (sinh key, đóng gói package...) thuộc tầng
/// Repository. Quy ước spec §1: GET → query string; POST/PUT → JSON body.
class ChannelApiClient {
  ChannelApiClient({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _asMap(dynamic data) =>
      DataConverter.cvToMap<String, dynamic>(data) ?? <String, dynamic>{};

  List<Map<String, dynamic>> _asListOfMaps(dynamic raw) =>
      DataConverter.cvToList<Map<String, dynamic>>(
        raw,
        (item) => _asMap(item),
      );

  // ------------------------------------------------------------- Devices

  /// `POST /api/v2/devices/register` — idempotent theo device_id (§3.1),
  /// trả về device_token (chỉ hiện 1 lần).
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

  /// `PUT /api/v2/devices/fcm-token` (§3.2).
  Future<void> updateFcmToken({required String fcmToken}) async {
    await apiClient.put(
      ApiEndpoints.updateFcmTokenV2,
      body: <String, dynamic>{'fcm_token': fcmToken},
    );
  }

  /// `PUT /api/v2/devices/name` — đổi tên hiển thị, server tự fan-out sang
  /// mọi kênh ACTIVE + request PENDING (§3.3, không rotate key).
  Future<void> updateDeviceName({required String deviceName}) async {
    await apiClient.put(
      ApiEndpoints.updateDeviceNameV2,
      body: <String, dynamic>{'device_name': deviceName},
    );
  }

  // ------------------------------------------------------------ Channels

  /// `POST /api/v2/channels` — T0 Owner package (§4.1). `channelId` do client
  /// sinh (UUID v4) để AAD envelope ràng buộc đúng channel trước khi commit.
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

  /// `GET /api/v2/channels` — các kênh caller đang ACTIVE, có kèm `role` (§4.2).
  Future<List<ChannelModel>> listChannels() async {
    final data = _asMap(await apiClient.get(ApiEndpoints.listChannelsV2));
    return _asListOfMaps(data['channels']).map(ChannelModel.fromMap).toList();
  }

  /// `GET /api/v2/channels/detail?channel_id=` — chi tiết + trạng thái caller (§4.3).
  Future<ChannelDetailModel> getChannelDetail({required String channelId}) async {
    final data = _asMap(
      await apiClient.get(
        ApiEndpoints.channelDetailV2,
        queryParameters: {'channel_id': channelId},
      ),
    );
    return ChannelDetailModel.fromMap(data);
  }

  /// `GET /api/v2/channels/members?channel_id=` — Owner thấy tất cả, Member
  /// chỉ ACTIVE (§4.4).
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

  /// `POST /api/v2/channels/revoke` — T4 thu hồi + rotate epoch (§4.6).
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

  // --------------------------------------------- Pairing sessions (QR invite)

  /// `POST /api/v2/channels/sessions` — Owner tạo phiên mời QR (§4.5, TTL 10').
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

  // --------------------------------------------------- Pairing requests (T1/T2/T6)

  /// `POST /api/v2/pairing/requests` — Member claim QR → request PENDING (§5.1).
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

  /// `GET /api/v2/pairing/requests/mine` — trạng thái request mình đã gửi (§5.2).
  Future<List<PairingRequestModel>> listMyRequests() async {
    final data = _asMap(await apiClient.get(ApiEndpoints.pairingMineV2));
    return _asListOfMaps(data['requests'])
        .map(PairingRequestModel.fromMap)
        .toList();
  }

  /// `GET /api/v2/channels/requests?channel_id=&status=PENDING` — hàng đợi duyệt (§5.3).
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

  /// `POST /api/v2/pairing/requests/approve` — T2 duyệt + rotate (§5.4).
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

  /// `POST /api/v2/pairing/requests/reject` — T6 từ chối (§5.5).
  Future<void> rejectPairingRequest({required String requestId}) async {
    await apiClient.post(
      ApiEndpoints.pairingRejectV2,
      body: <String, dynamic>{'request_id': requestId},
    );
  }

  /// `POST /api/v2/pairing/requests/cancel` — T6 hủy (chỉ requester, §5.6).
  Future<void> cancelPairingRequest({required String requestId}) async {
    await apiClient.post(
      ApiEndpoints.pairingCancelV2,
      body: <String, dynamic>{'request_id': requestId},
    );
  }

  // ------------------------------------------------------ Key envelope & messages

  /// `GET /api/v2/channels/key-envelope?channel_id=&epoch=` — envelope của
  /// caller; bỏ `epoch` → provisioned_epoch cao nhất (§6.1, mode "latest").
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

  /// `POST /api/v2/channels/messages` — T5 + T3 gửi OTP (chỉ Owner, §6.2).
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

  /// `GET /api/v2/messages?date=&tz_offset=` — đọc tin theo ngày, gộp mọi
  /// kênh caller đang ACTIVE (channel-agnostic, KL12, §6.3).
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
