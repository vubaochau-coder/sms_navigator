import '../../models/pairing_request_model.dart';
import '../../models/pairing_session_model.dart';
import '../../services/channel_api_service.dart';
import '../../services/channel_key_store.dart';
import '../../services/device_storage_service.dart';
import '../../services/pairing_api_service.dart';
import '../../utils/channel_crypto_helper.dart';
import '../join_channel_repository.dart';

class JoinChannelRepositoryImpl implements JoinChannelRepository {
  JoinChannelRepositoryImpl({
    required ChannelApiService channelApiService,
    required PairingApiService pairingApiService,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
    required DeviceStorageService deviceStorage,
  }) : _channelApi = channelApiService,
       _pairingApi = pairingApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper,
       _deviceStorage = deviceStorage;

  final ChannelApiService _channelApi;
  final PairingApiService _pairingApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;
  final DeviceStorageService _deviceStorage;

  @override
  Future<ClaimRequestResultModel> submitJoinRequest(InvitePayload invite) =>
      _pairingApi.claimPairingRequest(
        sessionId: invite.sessionId,
        pairingToken: invite.pairingToken,
        deviceName: '',
      );

  @override
  Future<ClaimRequestResultModel> claim({
    required InvitePayload invite,
    required String deviceName,
  }) => _pairingApi.claimPairingRequest(
    sessionId: invite.sessionId,
    pairingToken: invite.pairingToken,
    deviceName: deviceName,
  );

  @override
  Future<List<PairingRequestModel>> listMyRequests() => _pairingApi.listMyRequests();

  @override
  Future<void> cancelRequest(String requestId) =>
      _pairingApi.cancelPairingRequest(requestId: requestId);

  @override
  Future<int?> provisionChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  }) async {
    final identity = await _keyStore.loadIdentityKeyPair();
    if (identity == null) return null;
    final deviceId = await _deviceStorage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) return null;

    final envelope = await _channelApi.getKeyEnvelope(channelId: channelId);
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

  @override
  Future<int?> provisionLatestForApproved({required String channelId}) async {
    final detail = await _channelApi.getChannelDetail(channelId: channelId);
    if (detail.ownerPublicKey.isEmpty) return null;
    return provisionChannelKey(
      channelId: channelId,
      ownerPublicKeyBase64: detail.ownerPublicKey,
    );
  }

  @override
  Future<void> purgeChannelKeys(String channelId) =>
      _keyStore.purgeChannelKeys(channelId);
}
