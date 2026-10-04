/// File tập trung duy nhất định nghĩa toàn bộ các API Endpoints của SMS Navigator.
/// Giúp loại bỏ hoàn toàn việc hardcode chuỗi đường dẫn ở nhiều nơi khác nhau.
class ApiEndpoints {
  ApiEndpoints._();

  // --- Devices ---
  static const String registerDevice = '/api/v1/devices/register';
  static const String updateFcmToken = '/api/v1/devices/fcm-token';

  // --- Pairing Flow & Management ---
  static const String initPair = '/api/v1/pair/init';
  static const String confirmPair = '/api/v1/pair/confirm';
  static const String pairStatus = '/api/v1/pair/status';
  static const String pairedReceivers = '/api/v1/pair/receivers';
  static const String pairedSenders = '/api/v1/pair/senders';

  // --- Relay & History ---
  static const String relay = '/api/v1/relay';
  static const String relayHistory = '/api/v1/relay/history';

  // --- Devices v2 (Channel E2EE) ---
  static const String registerDeviceV2 = '/api/v2/devices/register';
  static const String updateDeviceNameV2 = '/api/v2/devices/name';
  static const String updateFcmTokenV2 = '/api/v2/devices/fcm-token';

  // --- Channels v2 ---
  static const String createChannelV2 = '/api/v2/channels';
  static const String listChannelsV2 = '/api/v2/channels';
  static const String channelDetailV2 = '/api/v2/channels/detail';
  static const String channelMembersV2 = '/api/v2/channels/members';
  static const String channelSessionsV2 = '/api/v2/channels/sessions';
  static const String channelRequestsV2 = '/api/v2/channels/requests';
  static const String channelKeyEnvelopeV2 = '/api/v2/channels/key-envelope';
  static const String channelMessagesV2 = '/api/v2/channels/messages';
  static const String channelRevokeV2 = '/api/v2/channels/revoke';

  // --- Pairing v2 ---
  static const String pairingClaimV2 = '/api/v2/pairing/requests';
  static const String pairingMineV2 = '/api/v2/pairing/requests/mine';
  static const String pairingApproveV2 = '/api/v2/pairing/requests/approve';
  static const String pairingRejectV2 = '/api/v2/pairing/requests/reject';
  static const String pairingCancelV2 = '/api/v2/pairing/requests/cancel';

  // --- Messages v2 (channel-agnostic day fetch) ---
  static const String messagesByDateV2 = '/api/v2/messages';
}
