import '../../../../core/services/device_storage_service.dart';
import '../../../../core/utils/channel_crypto_helper.dart';
import '../models/pairing_request_model.dart';
import '../models/pairing_session_model.dart';
import '../services/channel_api_client.dart';
import '../services/channel_key_store.dart';

/// Repository use case Member (MOBILE_FEATURES 3.1–3.6): claim QR → chờ duyệt
/// → được cấp key ngầm. Member chỉ decrypt, không sinh key (SRD 0).
class JoinChannelRepository {
  JoinChannelRepository({
    required ChannelApiClient apiClient,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
    required DeviceStorageService deviceStorage,
  }) : _api = apiClient,
       _keyStore = keyStore,
       _crypto = cryptoHelper,
       _deviceStorage = deviceStorage;

  final ChannelApiClient _api;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;
  final DeviceStorageService _deviceStorage;

  /// Gửi join request (3.3): claim QR sau khi user bấm xác nhận (3.2).
  /// Trả về thông tin kênh + trạng thái PENDING.
  Future<ClaimRequestResultModel> submitJoinRequest(InvitePayload invite) =>
      _api.claimPairingRequest(
        sessionId: invite.sessionId,
        pairingToken: invite.pairingToken,
        deviceName: '', // fallback; repository caller truyền tên qua [claim]
      );

  /// Claim với tên thiết bị user nhập/sửa trong dialog xác nhận (3.2).
  Future<ClaimRequestResultModel> claim({
    required InvitePayload invite,
    required String deviceName,
  }) => _api.claimPairingRequest(
    sessionId: invite.sessionId,
    pairingToken: invite.pairingToken,
    deviceName: deviceName,
  );

  /// Trạng thái các request mình đã gửi — màn "Đang chờ duyệt" (3.4) +
  /// reconcile khi mở app (SRD 7.3).
  Future<List<PairingRequestModel>> listMyRequests() => _api.listMyRequests();

  /// Hủy request (3.5) — chỉ khi còn PENDING.
  Future<void> cancelRequest(String requestId) =>
      _api.cancelPairingRequest(requestId: requestId);

  /// Key provisioning ngầm (SRD 7.3): sau khi được duyệt (APPROVED), fetch
  /// envelope mới nhất → ECDH(sk_my, pk_owner) unwrap → persist map
  /// `epoch → CK`. Không có màn hình riêng. Idempotent — envelope đã
  /// provision thì bỏ qua.
  Future<int?> provisionChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  }) async {
    final identity = await _keyStore.loadIdentityKeyPair();
    if (identity == null) return null;
    final deviceId = await _deviceStorage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) return null;

    final envelope = await _api.getKeyEnvelope(channelId: channelId);
    final alreadyProvisioned = await _keyStore.getChannelKey(
      channelId: channelId,
      epoch: envelope.keyEpoch,
    );
    if (alreadyProvisioned != null) return envelope.keyEpoch;

    final channelKey = await _crypto.unwrapKeyEnvelope(
      wrappedKeyBase64: envelope.wrappedKey,
      nonceBase64: envelope.nonce,
      myPrivateKeyBase64: identity.privateKeyBase64,
      ownerPublicKeyBase64: ownerPublicKeyBase64,
      channelId: channelId,
      keyEpoch: envelope.keyEpoch,
      myDeviceId: deviceId,
    );
    await _keyStore.saveChannelKey(
      channelId: channelId,
      epoch: envelope.keyEpoch,
      channelKeyBase64: channelKey,
    );
    return envelope.keyEpoch;
  }

  /// Provision sau APPROVED khi chưa biết pk_owner: tự fetch channel detail
  /// (chứa `owner_public_key`) rồi gọi [provisionChannelKey].
  Future<int?> provisionLatestForApproved({required String channelId}) async {
    final detail = await _api.getChannelDetail(channelId: channelId);
    if (detail.ownerPublicKey.isEmpty) return null;
    return provisionChannelKey(
      channelId: channelId,
      ownerPublicKeyBase64: detail.ownerPublicKey,
    );
  }

  /// Purge key material của 1 kênh (SRD 8.4/KL12) — khi bị revoke.
  Future<void> purgeChannelKeys(String channelId) =>
      _keyStore.purgeChannelKeys(channelId);
}
