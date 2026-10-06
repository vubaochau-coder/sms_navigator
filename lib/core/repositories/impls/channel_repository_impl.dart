import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../models/channel_detail_model.dart';
import '../../models/channel_member_model.dart';
import '../../models/channel_model.dart';
import '../../models/key_envelope_model.dart';
import '../../models/pairing_request_model.dart';
import '../../models/pairing_session_model.dart';
import '../../services/channel_api_service.dart';
import '../../services/channel_key_store.dart';
import '../../services/device_api_service.dart';
import '../../services/device_storage_service.dart';
import '../../services/pairing_api_service.dart';
import '../../utils/channel_crypto_helper.dart';
import '../channel_repository.dart';

/// Snapshot server cần cho một mutation membership (Package Pattern, SRD 4.0).
class _MutationSnapshot extends Equatable {
  final ChannelDetailModel detail;
  final List<ChannelMemberModel> activeMembers;

  const _MutationSnapshot({required this.detail, required this.activeMembers});

  @override
  List<Object?> get props => [detail, activeMembers];
}

class ChannelRepositoryImpl implements ChannelRepository {
  ChannelRepositoryImpl({
    required ChannelApiService channelApiService,
    required PairingApiService pairingApiService,
    required DeviceApiService deviceApiService,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
    required DeviceStorageService deviceStorage,
  }) : _channelApi = channelApiService,
       _pairingApi = pairingApiService,
       _deviceApi = deviceApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper,
       _deviceStorage = deviceStorage;

  final ChannelApiService _channelApi;
  final PairingApiService _pairingApi;
  final DeviceApiService _deviceApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;
  final DeviceStorageService _deviceStorage;

  // ------------------------------------------------------------- Đọc state

  @override
  Future<List<ChannelModel>> listChannels() => _channelApi.listChannels();

  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) =>
      _channelApi.getChannelDetail(channelId: channelId);

  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) =>
      _channelApi.getChannelMembers(channelId: channelId);

  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) =>
      _pairingApi.listChannelRequests(channelId: channelId);

  Future<_MutationSnapshot> _loadSnapshot(String channelId) async {
    final detail = await _channelApi.getChannelDetail(channelId: channelId);
    final members = await _channelApi.getChannelMembers(channelId: channelId);
    return _MutationSnapshot(
      detail: detail,
      activeMembers: members.where((m) => m.isActive).toList(),
    );
  }

  Future<IdentityKeyPair> _requireIdentity() async {
    final identity = await _keyStore.loadIdentityKeyPair();
    if (identity == null || identity.publicKeyBase64.isEmpty) {
      throw StateError('Thiết bị chưa có identity key — chưa đăng ký.');
    }
    return identity;
  }

  Future<String> _requireDeviceId() async {
    final deviceId = await _deviceStorage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      throw StateError('Thiết bị chưa đăng ký (device_id rỗng).');
    }
    return deviceId;
  }

  /// Wrap Channel Key cho từng device trong map (SRD 7.2 static ECDH).
  Future<List<PackageEnvelopeModel>> _buildEnvelopes({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    required String ownerPrivateKeyBase64,
    required Map<String, String> publicKeyByDeviceId,
  }) async {
    final envelopes = <PackageEnvelopeModel>[];
    for (final entry in publicKeyByDeviceId.entries) {
      final envelope = await _crypto.wrapKeyForDevice(
        channelKeyBase64: channelKeyBase64,
        ownerPrivateKeyBase64: ownerPrivateKeyBase64,
        receiverPublicKeyBase64: entry.value,
        channelId: channelId,
        keyEpoch: keyEpoch,
        receiverDeviceId: entry.key,
      );
      envelopes.add(
        PackageEnvelopeModel(
          deviceId: entry.key,
          keyEpoch: keyEpoch,
          wrappedKey: envelope.wrappedKeyBase64,
          nonce: envelope.nonceBase64,
          kekAlg: envelope.kekAlg,
        ),
      );
    }
    return envelopes;
  }

  // ------------------------------------------------------- T0 — tạo kênh

  @override
  Future<ChannelModel> createChannel(String name) async {
    final identity = await _requireIdentity();
    final deviceId = await _requireDeviceId();

    final channelId = generateUuidV4();
    final channelKey = _crypto.generateChannelKeyBase64();
    final selfEnvelope = await _crypto.wrapKeyForDevice(
      channelKeyBase64: channelKey,
      ownerPrivateKeyBase64: identity.privateKeyBase64,
      receiverPublicKeyBase64: identity.publicKeyBase64,
      channelId: channelId,
      keyEpoch: 1,
      receiverDeviceId: deviceId,
    );

    final response = await _channelApi.createChannel(
      name: name,
      channelId: channelId,
      package: PackageModel(
        baseEpoch: 1,
        baseMembershipVersion: 1,
        envelopes: [
          PackageEnvelopeModel(
            deviceId: deviceId,
            keyEpoch: 1,
            wrappedKey: selfEnvelope.wrappedKeyBase64,
            nonce: selfEnvelope.nonceBase64,
            kekAlg: selfEnvelope.kekAlg,
          ),
        ],
      ).toMap(),
    );

    await _keyStore.saveChannelKey(
      channelId: channelId,
      epoch: 1,
      channelKeyBase64: channelKey,
    );

    return ChannelModel(
      channelId: response['channel_id'] as String? ?? channelId,
      name: name,
      role: ChannelRole.owner,
      status: 'ACTIVE',
      currentEpoch: response['current_epoch'] as int? ?? 1,
      membershipVersion: response['membership_version'] as int? ?? 1,
      memberCount: 1,
      myJoinedEpoch: 1,
    );
  }

  // ----------------------------------------------- T2 — duyệt (auto-rotate)

  @override
  Future<int> approveRequest({
    required String channelId,
    required PairingRequestModel request,
  }) async {
    final identity = await _requireIdentity();
    final deviceId = await _requireDeviceId();
    final snapshot = await _loadSnapshot(channelId);
    final detail = snapshot.detail;

    final newEpoch = detail.currentEpoch + 1;
    final channelKey = _crypto.generateChannelKeyBase64();

    final publicKeyByDeviceId = <String, String>{
      for (final member in snapshot.activeMembers)
        if (member.publicKey.isNotEmpty) member.deviceId: member.publicKey,
      if (request.requesterPublicKey.isNotEmpty)
        request.requesterDeviceId: request.requesterPublicKey,
    };
    publicKeyByDeviceId[deviceId] = identity.publicKeyBase64;

    final envelopes = await _buildEnvelopes(
      channelId: channelId,
      keyEpoch: newEpoch,
      channelKeyBase64: channelKey,
      ownerPrivateKeyBase64: identity.privateKeyBase64,
      publicKeyByDeviceId: publicKeyByDeviceId,
    );

    final response = await _pairingApi.approvePairingRequest(
      requestId: request.requestId,
      package: PackageModel(
        baseEpoch: detail.currentEpoch,
        baseMembershipVersion: detail.membershipVersion,
        envelopes: envelopes,
      ).toMap(),
    );

    await _keyStore.saveChannelKey(
      channelId: channelId,
      epoch: newEpoch,
      channelKeyBase64: channelKey,
    );

    return response['current_epoch'] as int? ?? newEpoch;
  }

  @override
  Future<void> rejectRequest(String requestId) =>
      _pairingApi.rejectPairingRequest(requestId: requestId);

  // ----------------------------------------------- T4 — revoke (auto-rotate)

  @override
  Future<int> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
  }) async {
    final identity = await _requireIdentity();
    final deviceId = await _requireDeviceId();
    final snapshot = await _loadSnapshot(channelId);
    final detail = snapshot.detail;

    final newEpoch = detail.currentEpoch + 1;
    final channelKey = _crypto.generateChannelKeyBase64();

    final publicKeyByDeviceId = <String, String>{
      for (final member in snapshot.activeMembers)
        if (member.publicKey.isNotEmpty) member.deviceId: member.publicKey,
    };
    publicKeyByDeviceId[deviceId] = identity.publicKeyBase64;

    final envelopes = await _buildEnvelopes(
      channelId: channelId,
      keyEpoch: newEpoch,
      channelKeyBase64: channelKey,
      ownerPrivateKeyBase64: identity.privateKeyBase64,
      publicKeyByDeviceId: publicKeyByDeviceId,
    );

    final response = await _channelApi.revokeMembers(
      channelId: channelId,
      revokeDeviceIds: revokeDeviceIds,
      package: PackageModel(
        baseEpoch: detail.currentEpoch,
        baseMembershipVersion: detail.membershipVersion,
        envelopes: envelopes,
      ).toMap(),
    );

    await _keyStore.saveChannelKey(
      channelId: channelId,
      epoch: newEpoch,
      channelKeyBase64: channelKey,
    );

    return response['current_epoch'] as int? ?? newEpoch;
  }

  @override
  Future<PairingSessionModel> createPairingSession(String channelId) =>
      _pairingApi.createPairingSession(channelId: channelId);

  @override
  Future<void> renameDevice(String deviceName) =>
      _deviceApi.updateDeviceName(deviceName);

  @override
  Future<int?> provisionLatestChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  }) async {
    final identity = await _keyStore.loadIdentityKeyPair();
    if (identity == null) return null;
    final deviceId = await _deviceStorage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) return null;

    final envelope = await _channelApi.getKeyEnvelope(channelId: channelId);
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
}

/// Sinh UUID v4 (RFC 4122) từ Random.secure — không cần package ngoài.
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10xx
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
