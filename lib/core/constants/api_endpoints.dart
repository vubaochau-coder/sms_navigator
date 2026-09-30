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
  static const String pairedReceivers = '/api/v1/pair/receivers';
  static const String pairedSenders = '/api/v1/pair/senders';

  // --- URL Path Builders (Dành cho dynamic call không dùng Retrofit template) ---
  static String revokePairPath(String pairId) => '/api/v1/pair/$pairId';
  static String togglePairPath(String pairId) =>
      '/api/v1/pair/$pairId/toggle';

  // --- Relay & History ---
  static const String relay = '/api/v1/relay';
  static const String relayHistory = '/api/v1/relay/history';
}
