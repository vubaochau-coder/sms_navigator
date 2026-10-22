import '../../constants/api_endpoints.dart';
import '../../models/channel_detail_model.dart';
import '../../models/channel_member_model.dart';
import '../../models/channel_model.dart';
import '../../models/key_envelope_model.dart';
import '../../network/api_client.dart';
import '../../utils/data_converter.dart';
import '../channel_api_service.dart';

class ChannelApiServiceImpl implements ChannelApiService {
  ChannelApiServiceImpl({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _asMap(dynamic data) =>
      DataConverter.cvToMap<String, dynamic>(data) ?? <String, dynamic>{};

  List<Map<String, dynamic>> _asListOfMaps(dynamic raw) =>
      DataConverter.cvToList<Map<String, dynamic>>(
        raw,
        (item) => _asMap(item),
      );

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
  Future<ChannelDetailModel> getChannelDetail({
    required String channelId,
  }) async {
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
  Future<void> renameChannel({required String channelId, required String name}) async {
    await apiClient.put(
      ApiEndpoints.channelNameV2,
      body: <String, dynamic>{'channel_id': channelId, 'name': name},
    );
  }

  @override
  Future<void> leaveChannel({required String channelId}) async {
    await apiClient.post(ApiEndpoints.channelLeaveV2, body: <String, dynamic>{'channel_id': channelId});
  }

  @override
  Future<Map<String, dynamic>> rotateChannel({
    required String channelId,
    required Map<String, dynamic> package,
  }) async {
    return _asMap(
      await apiClient.post(
        ApiEndpoints.channelRotateV2,
        body: <String, dynamic>{'channel_id': channelId, 'package': package},
      ),
    );
  }

  @override
  Future<void> archiveChannel({required String channelId}) async {
    await apiClient.post(ApiEndpoints.channelArchiveV2, body: <String, dynamic>{'channel_id': channelId});
  }

  @override
  Future<Map<String, dynamic>> updateChannelWhitelist({
    required String channelId,
    required int keyEpoch,
    required String ciphertext,
    required String nonce,
    required int whitelistVersion,
  }) async {
    return _asMap(
      await apiClient.put(
        ApiEndpoints.channelWhitelistV2,
        body: <String, dynamic>{
          'channel_id': channelId,
          'key_epoch': keyEpoch,
          'ciphertext': ciphertext,
          'nonce': nonce,
          'whitelist_version': whitelistVersion,
        },
      ),
    );
  }
}
