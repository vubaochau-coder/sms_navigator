/// Tập trung 100% các key của Local Storage (SharedPreferences).
///
/// QUAN TRỌNG: Không được thay đổi giá trị các key đã tồn tại trong production
/// vì sẽ làm mất dữ liệu người dùng đã lưu (device token, pairing secret...).
abstract final class StorageKeys {
  // --- Device & Auth ---
  static const String deviceId = 'device_id';
  static const String deviceToken = 'device_token';
  static const String serverUrl = 'server_url';
  static const String fcmToken = 'fcm_token';

  // --- Pairing & Crypto Secrets ---
  static const String receiverPairId = 'receiver_pair_id';
  static const String receiverSharedSecret = 'receiver_shared_secret';

  // --- Channel E2EE (secure storage) ---
  static const String channelIdentityPrivateKey = 'channel_identity_private_key';
  static const String channelIdentityPublicKey = 'channel_identity_public_key';
  static const String channelKeyPrefix = 'channel_ck_';
  static const String channelKeyEpochsPrefix = 'channel_ck_epochs_';

  // --- Device Setup & Checklist ---
  static const String autostartAcknowledged = 'device_setup_autostart_ack';
  static const String dontPromptPermission = 'device_setup_dont_prompt_dialog';

  // --- Settings & App State ---
  static const String themeMode = 'app_theme_mode';

  // --- Receiver OTP History ---
  static const String receivedOtpsHistory = 'received_otps_history';
}
