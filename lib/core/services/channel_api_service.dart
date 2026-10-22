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

  /// `GET /key-envelopes` (§6.1b): mọi envelope của máy này theo kênh ACTIVE —
  /// một request cho mọi kênh, mọi epoch.
  Future<List<ChannelKeyEnvelopesModel>> listKeyEnvelopes({String? channelId});

  Future<Map<String, dynamic>> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
    required Map<String, dynamic> package,
  });

  /// `PUT /channels/name` — Owner đổi tên kênh (display-only).
  Future<void> renameChannel({required String channelId, required String name});

  /// `POST /channels/leave` — member tự rời kênh.
  Future<void> leaveChannel({required String channelId});

  /// `POST /channels/rotate` — Owner xoay khóa, không đổi membership.
  Future<Map<String, dynamic>> rotateChannel({
    required String channelId,
    required Map<String, dynamic> package,
  });

  /// `POST /channels/archive` — Owner giải tán kênh (không hoàn tác).
  Future<void> archiveChannel({required String channelId});

  Future<Map<String, dynamic>> updateChannelWhitelist({
    required String channelId,
    required int keyEpoch,
    required String ciphertext,
    required String nonce,
    required int whitelistVersion,
  });
}
