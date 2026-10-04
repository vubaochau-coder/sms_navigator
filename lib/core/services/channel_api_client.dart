import 'package:dio/dio.dart';

import '../models/channel_detail_model.dart';
import '../models/channel_member_model.dart';
import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/key_envelope_model.dart';
import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';

/// API Client v2 cho kiến trúc Kênh 1-to-N E2EE (SERVER_API_SPEC v1.5).
abstract class ChannelApiClient {
  Future<Map<String, dynamic>> registerDeviceV2({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String publicKey,
    String? fcmToken,
  });

  Future<void> updateFcmToken({required String fcmToken});

  Future<void> updateDeviceName({required String deviceName});

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

  Future<Map<String, dynamic>> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
    required Map<String, dynamic> package,
  });

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

  Future<KeyEnvelopeModel> getKeyEnvelope({
    required String channelId,
    int? epoch,
  });

  Future<SendMessageResultModel> sendMessageV2({
    required String channelId,
    required int requestEpoch,
    required String ciphertext,
    required String nonce,
  });

  Future<({List<ChannelMessageModel> messages, bool truncated})>
  fetchMessagesByDate({
    required String date,
    int tzOffset = 0,
    CancelToken? cancelToken,
  });
}
