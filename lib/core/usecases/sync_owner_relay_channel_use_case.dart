import '../models/channel_detail_model.dart';
import '../models/channel_model.dart';
import '../repositories/channel_repository.dart';
import '../repositories/whitelist_repository.dart';
import '../services/channel_key_store.dart';
import '../services/device_storage_service.dart';
import '../utils/app_logger.dart';
import '../services/relay_channel_bridge.dart';

/// Đồng bộ **toàn bộ** kênh Owner ACTIVE và Channel Key mới nhất xuống native
/// relay, để `OtpRelayWorker` mã hóa đúng epoch ngay cả khi app bị kill.
///
/// Idempotent — gọi lúc khởi động, khi app quay lại foreground, và sau mỗi
/// mutation membership. Mỗi lần chạy cũng tự phục hồi:
/// - thiếu key epoch hiện tại → unwrap lại self-envelope từ server;
/// - whitelist blob còn mã hóa ở epoch cũ → mã hóa lại ở epoch hiện tại;
/// - SMS bị "park" vì thiếu key → gửi lại.
class SyncOwnerRelayChannelUseCase {
  final ChannelRepository _channelRepository;
  final ChannelKeyStore _keyStore;
  final DeviceStorageService _deviceStorage;
  final RelayChannelBridge _relayBridge;
  final WhitelistRepository? _whitelistRepository;

  SyncOwnerRelayChannelUseCase({
    required ChannelRepository channelRepository,
    required ChannelKeyStore keyStore,
    required DeviceStorageService deviceStorage,
    required RelayChannelBridge relayBridge,
    WhitelistRepository? whitelistRepository,
  })  : _channelRepository = channelRepository,
        _keyStore = keyStore,
        _deviceStorage = deviceStorage,
        _relayBridge = relayBridge,
        _whitelistRepository = whitelistRepository;

  /// - [channelId] + [expectedEpoch]: gợi ý epoch vừa rotate cho kênh đó
  ///   (danh sách kênh từ server có thể chưa phản ánh kịp).
  ///
  /// Trả về `true` nếu ít nhất một kênh đã được đồng bộ xuống native.
  Future<bool> call({String? channelId, int? expectedEpoch}) async {
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
      for (final channel in ownerChannels) {
        final hint = channel.channelId == channelId ? expectedEpoch : null;
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

      for (final snapshot in snapshots) {
        await _syncWhitelist(snapshot, details);
      }

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

    if (key == null || key.isEmpty) {
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
    Map<String, ChannelDetailModel> details,
  ) async {
    final whitelistRepo = _whitelistRepository;
    if (whitelistRepo == null) return;
    try {
      final detail = await _detail(snapshot.channelId, details);
      final blob = detail.whitelist;
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
