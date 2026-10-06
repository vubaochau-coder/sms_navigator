import '../models/channel_detail_model.dart';
import '../models/channel_member_model.dart';
import '../models/channel_model.dart';
import '../models/key_envelope_model.dart';

/// Service API Kênh (BE: ChannelV2Controller, API spec §4).
abstract class ChannelApiService {
  Future<Map<String, dynamic>> createChannel({
    required String name,
    required String channelId,
    required Map<String, dynamic> package,
  });

  Future<List<ChannelModel>> listChannels();

  Future<ChannelDetailModel> getChannelDetail({required String channelId});

  Future<List<ChannelMemberModel>> getChannelMembers({
    required String channelId,
  });

  Future<KeyEnvelopeModel> getKeyEnvelope({
    required String channelId,
    int? epoch,
  });

  Future<Map<String, dynamic>> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
    required Map<String, dynamic> package,
  });
}
