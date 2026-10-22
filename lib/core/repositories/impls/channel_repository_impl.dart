import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../models/channel_detail_model.dart';
import '../../models/channel_member_model.dart';
import '../../models/channel_model.dart';
import '../../models/key_envelope_model.dart';
import '../../models/pairing_request_model.dart';
import '../../models/pairing_session_model.dart';
import '../../models/request_history_result.dart';
import '../../errors/app_exceptions.dart';
import '../../models/whitelist_config_model.dart';
import '../../services/channel_api_service.dart';
import '../../services/channel_key_store.dart';
import '../../services/device_api_service.dart';
import '../../services/device_storage_service.dart';
import '../../services/pairing_api_service.dart';
import '../../services/relay_channel_bridge.dart';
import '../../utils/app_logger.dart';
import '../../crypto/channel_crypto_helper.dart';
import '../channel_repository.dart';
import '../whitelist_repository.dart';

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
    WhitelistRepository? whitelistRepository,
    RelayChannelBridge? relayBridge,
    Duration retryBaseDelay = const Duration(seconds: 1),
  }) : _channelApi = channelApiService,
       _pairingApi = pairingApiService,
       _deviceApi = deviceApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper,
       _deviceStorage = deviceStorage,
       _whitelistRepository = whitelistRepository,
       _relayBridge = relayBridge,
       _retryBaseDelay = retryBaseDelay;

  /// Số lần gửi lại cùng một package khi mất mạng / timeout. An toàn vì server
  /// nhận diện retry trùng package và trả kết quả đã commit (idempotent).
  static const int _rotationNetworkRetries = 2;

  final ChannelApiService _channelApi;
  final PairingApiService _pairingApi;
  final DeviceApiService _deviceApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;
  final DeviceStorageService _deviceStorage;
  final WhitelistRepository? _whitelistRepository;
  final RelayChannelBridge? _relayBridge;
  final Duration _retryBaseDelay;

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

  @override
  Future<RequestHistoryResult> listRequestHistory(String channelId, {String? before}) =>
      _pairingApi.listRequestHistory(channelId: channelId, before: before);

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

  /// Xoay khóa nhất quán giữa server, key store Dart và native relay:
  ///
  /// 1. Lưu key mới vào key store + stage xuống native **trước** khi gọi
  ///    server — nếu app bị kill ngay sau khi server commit, key vẫn còn.
  /// 2. Gọi server với package; mất mạng/timeout → gửi lại ĐÚNG package đó
  ///    (server trả kết quả đã commit, không xoay thêm epoch).
  /// 3. Thành công → promote ở native. Server từ chối dứt khoát (4xx) →
  ///    discard. Kết quả không rõ (mạng/5xx) → giữ pending để worker và
  ///    reconcile tự phục hồi.
  Future<int> _rotate({
    required String channelId,
    required String? channelName,
    required int newEpoch,
    required String channelKeyBase64,
    required Future<Map<String, dynamic>> Function() commit,
  }) async {
    await _keyStore.saveChannelKey(
      channelId: channelId,
      epoch: newEpoch,
      channelKeyBase64: channelKeyBase64,
    );
    await _relayBridge?.stageKey(
      channelId: channelId,
      channelName: channelName,
      keyEpoch: newEpoch,
      channelKeyBase64: channelKeyBase64,
    );

    var attempt = 0;
    while (true) {
      try {
        final response = await commit();
        final committedEpoch = response['current_epoch'] as int? ?? newEpoch;
        await _relayBridge?.promoteKey(channelId: channelId, keyEpoch: committedEpoch);
        return committedEpoch;
      } on AppException catch (e) {
        final definitiveRejection =
            e is ApiException && e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500;
        if (definitiveRejection) {
          // 4xx: server did not commit this package (409 MEMBERSHIP_CHANGED,
          // 422 PACKAGE_INCOMPLETE, 403…) — the staged key is garbage.
          await _relayBridge?.discardKey(channelId: channelId, keyEpoch: newEpoch);
          rethrow;
        }
        // Outcome unknown (network, timeout, 5xx, 401): the rotation may
        // have committed. Retry the identical package; if still failing,
        // keep the key pending for worker self-heal / next reconcile.
        final retryable = e is NetworkException || e is ApiException;
        if (!retryable || attempt >= _rotationNetworkRetries) {
          AppLogger.w(
            'ChannelRepository',
            'Rotation of $channelId to epoch $newEpoch: outcome unknown (${e.runtimeType}) — key kept pending',
          );
          rethrow;
        }
        attempt++;
        await Future<void>.delayed(_retryBaseDelay * attempt);
      }
    }
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

    // Built once: retries must resend the byte-identical package.
    final package = PackageModel(
      baseEpoch: detail.currentEpoch,
      baseMembershipVersion: detail.membershipVersion,
      envelopes: envelopes,
    ).toMap();

    final committedEpoch = await _rotate(
      channelId: channelId,
      channelName: detail.name,
      newEpoch: newEpoch,
      channelKeyBase64: channelKey,
      commit: () => _pairingApi.approvePairingRequest(
        requestId: request.requestId,
        package: package,
      ),
    );

    // §8.4: Re-encrypt whitelist blob sau rotation (best-effort; nếu gián
    // đoạn, SyncOwnerRelayChannelUseCase sẽ tự mã hóa lại ở lần sync sau)
    await _reEncryptWhitelistAfterRotation(
      channelId: channelId,
      detail: detail,
      newEpoch: newEpoch,
      channelKeyBase64: channelKey,
    );

    return committedEpoch;
  }

  @override
  Future<void> rejectRequest(String requestId) =>
      _pairingApi.rejectPairingRequest(requestId: requestId);

  // ----------------------------------------------- T4 — revoke (auto-rotate)

  @override
  Future<void> renameChannel({required String channelId, required String name}) =>
      _channelApi.renameChannel(channelId: channelId, name: name);

  @override
  Future<void> leaveChannel(String channelId) async {
    await _channelApi.leaveChannel(channelId: channelId);
    // KL12: không còn là member → xoá key material của kênh trên máy.
    await _keyStore.purgeChannelKeys(channelId);
  }

  @override
  Future<void> archiveChannel(String channelId) => _channelApi.archiveChannel(channelId: channelId);

  @override
  Future<int> rotateChannelKey(String channelId) async {
    final identity = await _requireIdentity();
    final deviceId = await _requireDeviceId();
    final snapshot = await _loadSnapshot(channelId);
    final detail = snapshot.detail;

    final newEpoch = detail.currentEpoch + 1;
    final channelKey = _crypto.generateChannelKeyBase64();

    // {Owner} ∪ ACTIVE — người đã rời có status REVOKED nên không có ở đây.
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

    // Built once: retries must resend the byte-identical package.
    final package = PackageModel(
      baseEpoch: detail.currentEpoch,
      baseMembershipVersion: detail.membershipVersion,
      envelopes: envelopes,
    ).toMap();

    final committedEpoch = await _rotate(
      channelId: channelId,
      channelName: detail.name,
      newEpoch: newEpoch,
      channelKeyBase64: channelKey,
      commit: () => _channelApi.rotateChannel(channelId: channelId, package: package),
    );

    await _reEncryptWhitelistAfterRotation(
      channelId: channelId,
      detail: detail,
      newEpoch: newEpoch,
      channelKeyBase64: channelKey,
    );

    return committedEpoch;
  }

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

    // Envelope set = {Owner} ∪ ACTIVE còn lại — KHÔNG wrap key mới cho máy bị
    // thu hồi (server cũng từ chối với 422 PACKAGE_INCOMPLETE).
    final revoked = revokeDeviceIds.toSet();
    final publicKeyByDeviceId = <String, String>{
      for (final member in snapshot.activeMembers)
        if (member.publicKey.isNotEmpty && !revoked.contains(member.deviceId)) member.deviceId: member.publicKey,
    };
    publicKeyByDeviceId[deviceId] = identity.publicKeyBase64;

    final envelopes = await _buildEnvelopes(
      channelId: channelId,
      keyEpoch: newEpoch,
      channelKeyBase64: channelKey,
      ownerPrivateKeyBase64: identity.privateKeyBase64,
      publicKeyByDeviceId: publicKeyByDeviceId,
    );

    // Built once: retries must resend the byte-identical package.
    final package = PackageModel(
      baseEpoch: detail.currentEpoch,
      baseMembershipVersion: detail.membershipVersion,
      envelopes: envelopes,
    ).toMap();

    final committedEpoch = await _rotate(
      channelId: channelId,
      channelName: detail.name,
      newEpoch: newEpoch,
      channelKeyBase64: channelKey,
      commit: () => _channelApi.revokeMembers(
        channelId: channelId,
        revokeDeviceIds: revokeDeviceIds,
        package: package,
      ),
    );

    // §8.4: Re-encrypt whitelist blob sau rotation (best-effort; nếu gián
    // đoạn, SyncOwnerRelayChannelUseCase sẽ tự mã hóa lại ở lần sync sau)
    await _reEncryptWhitelistAfterRotation(
      channelId: channelId,
      detail: detail,
      newEpoch: newEpoch,
      channelKeyBase64: channelKey,
    );

    return committedEpoch;
  }

  /// §8.4: Re-encrypt whitelist blob bằng khóa epoch mới sau khi rotate.
  Future<void> _reEncryptWhitelistAfterRotation({
    required String channelId,
    required ChannelDetailModel detail,
    required int newEpoch,
    required String channelKeyBase64,
  }) async {
    final whitelistRepo = _whitelistRepository;
    if (whitelistRepo == null) return;

    try {
      final oldBlob = detail.whitelist;
      WhitelistConfigModel? config;
      try {
        config = await whitelistRepo.getWhitelist(channelId);
      } catch (_) {}

      if ((config == null || config.isEmptyList) && oldBlob != null) {
        final oldKey = await _keyStore.getChannelKey(
          channelId: channelId,
          epoch: oldBlob.keyEpoch,
        );
        if (oldKey != null && oldKey.isNotEmpty) {
          config = await whitelistRepo.syncWhitelistFromServer(
            channelId: channelId,
            keyEpoch: oldBlob.keyEpoch,
            channelKeyBase64: oldKey,
            blob: oldBlob,
          );
        }
      }

      if (config != null && (oldBlob != null || !config.isEmptyList)) {
        final currentVersion = oldBlob?.whitelistVersion ?? config.version;
        final nextVersion = currentVersion + 1;
        await whitelistRepo.saveWhitelist(
          channelId: channelId,
          config: config.copyWith(version: nextVersion),
          keyEpoch: newEpoch,
          channelKeyBase64: channelKeyBase64,
        );
        AppLogger.i(
          'ChannelRepository',
          'Re-encrypted whitelist for channel $channelId at epoch $newEpoch (v$nextVersion)',
        );
      }
    } catch (e) {
      AppLogger.w(
        'ChannelRepository',
        'Failed to re-encrypt whitelist after rotation (continuing)',
        e,
      );
    }
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
