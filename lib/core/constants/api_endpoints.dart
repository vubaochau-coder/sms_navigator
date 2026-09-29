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
  static const String pairStatus = '/api/v1/pair/status/{pairId}';
  static const String revokePair = '/api/v1/pair/{pairId}';
  static const String togglePair = '/api/v1/pair/{pairId}/toggle';
  static const String pairedReceivers = '/api/v1/pair/receivers';
  static const String pairedSenders = '/api/v1/pair/senders';

  // --- Relay & History ---
  static const String relay = '/api/v1/relay';
  static const String pendingMessages = '/api/v1/relay/pending/{pairId}';
  static const String relayHistory = '/api/v1/relay/history';

  // --- Health Check ---
  static const String health = '/api/v1/health';

  // --- URL Path Builders (Dành cho dynamic call không dùng Retrofit template) ---
  static String pairStatusPath(String pairId) => '/api/v1/pair/status/$pairId';
  static String revokePairPath(String pairId) => '/api/v1/pair/$pairId';
  static String togglePairPath(String pairId) => '/api/v1/pair/$pairId/toggle';
  static String pendingMessagesPath(String pairId) => '/api/v1/relay/pending/$pairId';
}
