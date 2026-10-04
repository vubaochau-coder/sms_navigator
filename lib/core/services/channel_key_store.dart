import '../utils/channel_crypto_helper.dart';

/// Kho lưu trữ an toàn cho key material của kiến trúc Channel E2EE:
/// - Identity key X25519 của thiết bị (SRD 3.1, reinstall = identity mới).
/// - Map `epoch → Channel Key` cho từng kênh (SRD 8.4 — giữ mọi epoch còn
///   nằm trong retention để decrypt được tin nhắn ngày cũ).
abstract class ChannelKeyStore {
  /// Đọc identity key; nếu chưa có thì sinh mới và lưu vào secure storage.
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair();

  /// Đọc identity key (không sinh mới); null nếu thiết bị chưa đăng ký.
  Future<IdentityKeyPair?> loadIdentityKeyPair();

  /// Đọc Channel Key của 1 kênh ở 1 epoch; null nếu chưa được provision.
  Future<String?> getChannelKey({required String channelId, required int epoch});

  /// Lưu Channel Key cho (channelId, epoch).
  Future<void> saveChannelKey({
    required String channelId,
    required int epoch,
    required String channelKeyBase64,
  });

  /// Danh sách epoch đã provision của 1 kênh (tăng dần).
  Future<List<int>> listProvisionedEpochs(String channelId);

  /// Purge toàn bộ key material của 1 kênh (policy khi bị revoke — SRD 8.4).
  Future<void> purgeChannelKeys(String channelId);
}
