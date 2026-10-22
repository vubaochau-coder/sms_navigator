import '../models/channel_detail_model.dart';
import '../models/channel_model.dart';
import '../repositories/channel_repository.dart';
import '../repositories/whitelist_repository.dart';
import '../services/channel_key_store.dart';
import '../services/device_storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/bounded_concurrency.dart';
import 'sync_channel_keys_use_case.dart';
import '../services/relay_channel_bridge.dart';

/// Đồng bộ **toàn bộ** kênh Owner ACTIVE và Channel Key mới nhất xuống native
/// relay, để `OtpRelayWorker` mã hóa đúng epoch ngay cả khi app bị kill.
///
/// Idempotent — gọi lúc khởi động, khi app quay lại foreground, và sau mỗi
/// mutation membership. Mỗi lần chạy cũng tự phục hồi:
/// - thiếu key epoch hiện tại → unwrap lại self-envelope từ server;
/// - whitelist blob còn mã hóa ở epoch cũ → mã hóa lại ở epoch hiện tại;
/// - SMS bị "park" vì thiếu key → gửi lại;
/// - có member tự rời (`rotation_pending`) → xoay khóa (BACKLOG 1.4).
class SyncOwnerRelayChannelUseCase {
  final ChannelRepository _channelRepository;
  final ChannelKeyStore _keyStore;
  final DeviceStorageService _deviceStorage;
  final RelayChannelBridge _relayBridge;
  final WhitelistRepository? _whitelistRepository;
  final SyncChannelKeysUseCase? _syncChannelKeys;

  SyncOwnerRelayChannelUseCase({
    required ChannelRepository channelRepository,
    required ChannelKeyStore keyStore,
    required DeviceStorageService deviceStorage,
    required RelayChannelBridge relayBridge,
    WhitelistRepository? whitelistRepository,
    SyncChannelKeysUseCase? syncChannelKeys,
  })  : _channelRepository = channelRepository,
        _keyStore = keyStore,
        _deviceStorage = deviceStorage,
        _relayBridge = relayBridge,
        _whitelistRepository = whitelistRepository,
        _syncChannelKeys = syncChannelKeys;

  /// - [channelId] + [expectedEpoch]: gợi ý epoch vừa rotate cho kênh đó
  ///   (danh sách kênh từ server có thể chưa phản ánh kịp).
  ///
  /// Trả về `true` nếu ít nhất một kênh đã được đồng bộ xuống native.
  ///
  /// Gọi không tham số (khởi động `app.dart`, tab Kênh, mỗi lần quay lại
  /// foreground) → single-flight và bỏ qua nếu vừa xong trong
  /// [idleSyncInterval] (FLOW_AUDIT P1/P2). Có [channelId] (sau mutation) →
  /// luôn chạy.
  Future<bool> call({String? channelId, int? expectedEpoch}) {
    final targeted = channelId != null || expectedEpoch != null;
    if (!targeted) {
      final running = _idleInFlight;
      if (running != null) return running;
      final last = _lastIdleSuccess;
      if (last != null && DateTime.now().difference(last.at) < idleSyncInterval) {
        return Future.value(last.result);
      }
      final run = _sync().then((result) {
        _lastIdleSuccess = (at: DateTime.now(), result: result);
        return result;
      }).whenComplete(() => _idleInFlight = null);
      _idleInFlight = run;
      return run;
    }
    _lastIdleSuccess = null;
    return _sync(channelId: channelId, expectedEpoch: expectedEpoch);
  }

  static const Duration idleSyncInterval = Duration(seconds: 10);
  Future<bool>? _idleInFlight;
  ({DateTime at, bool result})? _lastIdleSuccess;

  Future<bool> _sync({String? channelId, int? expectedEpoch}) async {
    try {
      final token = await _deviceStorage.getDeviceToken();
      if (token == null || token.isEmpty) {
        AppLogger.w('SyncOwnerRelayChannel', 'Missing device token for relay');
        return false;
      }
      final serverUrl = await _deviceStorage.getServerUrl();

      final channels = await _channelRepository.listChannels();
      final ownerChannels =
          channels.where((c) => c.isOwner && c.status == 'ACTIVE').toList();

      final snapshots = <RelayChannelSnapshot>[];
      // Owner channels whose key could not be resolved this run: native keeps
      // whatever it already has for them instead of dropping the channel.
      final retain = <String>[];
      final details = <String, ChannelDetailModel>{};
      final byId = {for (final c in ownerChannels) c.channelId: c};
      final rotatedNow = <String>{};
      for (final channel in ownerChannels) {
        final rotated = await _settlePendingRotation(channel, details);
        if (rotated != null) rotatedNow.add(channel.channelId);
        final hint = rotated ?? (channel.channelId == channelId ? expectedEpoch : null);
        final snapshot = await _snapshotFor(channel, hint, details);
        if (snapshot != null) {
          snapshots.add(snapshot);
        } else {
          retain.add(channel.channelId);
        }
      }

      await _relayBridge.setCredentials(deviceToken: token, apiBaseUrl: serverUrl);
      final synced = await _relayBridge.replaceRelayChannels(snapshots, retainChannelIds: retain);
      AppLogger.i(
        'SyncOwnerRelayChannel',
        'Synced ${snapshots.length}/${ownerChannels.length} owner channel(s) to native (ack $synced)',
      );

      final flushed = await _relayBridge.flushParkedMessages();
      if (flushed > 0) {
        AppLogger.i('SyncOwnerRelayChannel', 'Re-enqueued $flushed parked SMS');
      }

      // Mỗi kênh cần 1 detail (whitelist blob chỉ có ở đó) — song song có
      // giới hạn thay vì tuần tự (BACKLOG 3.4).
      // Kênh vừa xoay khoá ở lượt này: rotate đã tự mã hoá lại whitelist, blob
      // trong danh sách đã cũ → bỏ qua.
      await forEachBounded<RelayChannelSnapshot>(
        snapshots.where((snapshot) => !rotatedNow.contains(snapshot.channelId)),
        (snapshot) => _syncWhitelist(snapshot, byId[snapshot.channelId], details),
        concurrency: 4,
      );

      return snapshots.isNotEmpty;
    } catch (e, stack) {
      AppLogger.w('SyncOwnerRelayChannel', 'Sync failed with error', e, stack);
      return false;
    }
  }

  Future<RelayChannelSnapshot?> _snapshotFor(
    ChannelModel channel,
    int? expectedEpoch,
    Map<String, ChannelDetailModel> details,
  ) async {
    var epoch = expectedEpoch != null && expectedEpoch > channel.currentEpoch
        ? expectedEpoch
        : channel.currentEpoch;
    var key = await _keyStore.getChannelKey(channelId: channel.channelId, epoch: epoch);

    final keySync = _syncChannelKeys;
    if ((key == null || key.isEmpty) && keySync != null) {
      // Self-heal: Owner luôn có self-envelope cho mọi epoch (KL4) — lấy hết
      // epoch còn thiếu của kênh này bằng 1 request, không cần detail.
      try {
        await keySync(channelId: channel.channelId);
        key = await _keyStore.getChannelKey(channelId: channel.channelId, epoch: epoch);
        if ((key == null || key.isEmpty) && epoch != channel.currentEpoch) {
          epoch = channel.currentEpoch;
          key = await _keyStore.getChannelKey(channelId: channel.channelId, epoch: epoch);
        }
      } catch (e) {
        AppLogger.w('SyncOwnerRelayChannel', 'Key sync failed for ${channel.channelId}', e);
      }
    } else if (key == null || key.isEmpty) {
      // Self-heal: Owner always has a self-envelope for the current epoch.
      try {
        final detail = await _detail(channel.channelId, details);
        final recovered = await _channelRepository.provisionLatestChannelKey(
          channelId: channel.channelId,
          ownerPublicKeyBase64: detail.ownerPublicKey,
        );
        if (recovered != null) {
          epoch = recovered;
          key = await _keyStore.getChannelKey(channelId: channel.channelId, epoch: epoch);
        }
      } catch (e) {
        AppLogger.w('SyncOwnerRelayChannel', 'Key recovery failed for ${channel.channelId}', e);
      }
    }

    if (key == null || key.isEmpty) {
      AppLogger.w(
        'SyncOwnerRelayChannel',
        'Missing channel key for ${channel.channelId} at epoch $epoch — skipped',
      );
      return null;
    }

    return RelayChannelSnapshot(
      channelId: channel.channelId,
      channelName: channel.name,
      keyEpoch: epoch,
      channelKeyBase64: key,
    );
  }

  /// Best-effort: kéo whitelist từ server xuống native, và nếu blob vẫn mã hóa
  /// ở epoch cũ (rotate xong nhưng re-encrypt bị gián đoạn) thì mã hóa lại ở
  /// epoch hiện tại để member mới (chỉ có key epoch mới) đọc được.
  Future<void> _syncWhitelist(
    RelayChannelSnapshot snapshot,
    ChannelModel? listed,
    Map<String, ChannelDetailModel> details,
  ) async {
    final whitelistRepo = _whitelistRepository;
    if (whitelistRepo == null) return;
    try {
      // Server mới trả whitelist ngay trong GET /channels → không cần detail
      // cho từng kênh mỗi lần sync / mỗi lần app quay lại foreground (FLOW_AUDIT P2).
      final blob = listed != null && listed.hasRelayMetadata
          ? listed.whitelistBlob
          : (await _detail(snapshot.channelId, details)).whitelist;
      if (blob == null) return;

      final blobKey = blob.keyEpoch == snapshot.keyEpoch
          ? snapshot.channelKeyBase64
          : await _keyStore.getChannelKey(channelId: snapshot.channelId, epoch: blob.keyEpoch);
      if (blobKey == null || blobKey.isEmpty) {
        AppLogger.w(
          'SyncOwnerRelayChannel',
          'Cannot sync whitelist: key for epoch ${blob.keyEpoch} not found in keyStore',
        );
        return;
      }

      final config = await whitelistRepo.syncWhitelistFromServer(
        channelId: snapshot.channelId,
        keyEpoch: blob.keyEpoch,
        channelKeyBase64: blobKey,
        blob: blob,
      );

      if (config != null && blob.keyEpoch < snapshot.keyEpoch) {
        await whitelistRepo.saveWhitelist(
          channelId: snapshot.channelId,
          config: config.copyWith(version: blob.whitelistVersion + 1),
          keyEpoch: snapshot.keyEpoch,
          channelKeyBase64: snapshot.channelKeyBase64,
        );
        AppLogger.i(
          'SyncOwnerRelayChannel',
          'Healed whitelist of ${snapshot.channelId}: epoch ${blob.keyEpoch} → ${snapshot.keyEpoch}',
        );
      }
    } catch (e) {
      AppLogger.w('SyncOwnerRelayChannel', 'Best-effort whitelist sync failed (continuing)', e);
    }
  }

  /// Member đã tự rời mà chưa xoay khóa → Owner xoay ngay (người rời vẫn giữ
  /// key epoch hiện tại). Trả về epoch mới, hoặc null nếu không cần / lỗi —
  /// lỗi để lần sync sau thử lại, relay vẫn chạy ở epoch cũ.
  Future<int?> _settlePendingRotation(ChannelModel channel, Map<String, ChannelDetailModel> details) async {
    final channelId = channel.channelId;
    try {
      // Danh sách đã có cờ → chỉ đọc detail khi server cũ chưa trả field này.
      final pending = channel.rotationPending ?? (await _detail(channelId, details)).rotationPending;
      if (!pending) return null;
      final epoch = await _channelRepository.rotateChannelKey(channelId);
      details.remove(channelId); // detail cũ đã lỗi thời (epoch, whitelist)
      AppLogger.i('SyncOwnerRelayChannel', 'Rotated $channelId to epoch $epoch after a member left');
      return epoch;
    } catch (e) {
      AppLogger.w('SyncOwnerRelayChannel', 'Pending rotation of $channelId failed (retry next sync)', e);
      return null;
    }
  }

  Future<ChannelDetailModel> _detail(
    String channelId,
    Map<String, ChannelDetailModel> cache,
  ) async {
    final cached = cache[channelId];
    if (cached != null) return cached;
    final detail = await _channelRepository.getChannelDetail(channelId);
    cache[channelId] = detail;
    return detail;
  }
}
