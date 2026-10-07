import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/channel_model.dart';
import '../repositories/channel_repository.dart';
import '../services/channel_key_store.dart';
import '../services/device_storage_service.dart';
import '../services/native_relay_service.dart';
import '../utils/app_logger.dart';

/// UseCase đồng bộ kênh Owner và Channel Key mới nhất xuống Native SharedPreferences & SecureVault.
/// Đảm bảo OtpRelayWorker có khóa mới nhất để mã hóa SMS ngay cả khi app bị kill (chống 409 EPOCH_OUTDATED).
class SyncOwnerRelayChannelUseCase {
  final ChannelRepository _channelRepository;
  final ChannelKeyStore _keyStore;
  final DeviceStorageService _deviceStorage;
  final NativeRelayService _nativeRelayService;

  SyncOwnerRelayChannelUseCase({
    required ChannelRepository channelRepository,
    required ChannelKeyStore keyStore,
    required DeviceStorageService deviceStorage,
    required NativeRelayService nativeRelayService,
  })  : _channelRepository = channelRepository,
        _keyStore = keyStore,
        _deviceStorage = deviceStorage,
        _nativeRelayService = nativeRelayService;

  /// Thực hiện đồng bộ:
  /// - [channelId]: Kênh cụ thể cần đồng bộ. Nếu null, chọn kênh Owner ACTIVE đầu tiên.
  /// - [expectedEpoch]: Epoch mong đợi (nếu vừa rotate key).
  Future<bool> call({String? channelId, int? expectedEpoch}) async {
    try {
      final channels = await _channelRepository.listChannels();
      final ownerChannels = channels.where((c) => c.isOwner && c.status == 'ACTIVE').toList();

      if (ownerChannels.isEmpty) {
        AppLogger.i('SyncOwnerRelayChannel', 'No active owner channels found, clearing native relay channel.');
        await _nativeRelayService.clearActiveRelayChannel();
        return false;
      }

      final targetChannel = channelId != null
          ? ownerChannels.firstWhere(
              (c) => c.channelId == channelId,
              orElse: () => ownerChannels.first,
            )
          : ownerChannels.first;

      final epochToUse = expectedEpoch != null && expectedEpoch > targetChannel.currentEpoch
          ? expectedEpoch
          : targetChannel.currentEpoch;

      final channelKeyBase64 = await _keyStore.getChannelKey(
        channelId: targetChannel.channelId,
        epoch: epochToUse,
      );

      if (channelKeyBase64 == null || channelKeyBase64.isEmpty) {
        AppLogger.w(
          'SyncOwnerRelayChannel',
          'Missing channel key for ${targetChannel.channelId} at epoch $epochToUse',
        );
        return false;
      }

      final token = await _deviceStorage.getDeviceToken();
      if (token == null || token.isEmpty) {
        AppLogger.w(
          'SyncOwnerRelayChannel',
          'Missing device token for relay',
        );
        return false;
      }

      final serverUrl = await _deviceStorage.getServerUrl();

      final updated = await _nativeRelayService.setActiveRelayChannel(
        channelId: targetChannel.channelId,
        channelName: targetChannel.name,
        keyEpoch: epochToUse,
        channelKeyBase64: channelKeyBase64,
        deviceToken: token,
        apiBaseUrl: serverUrl,
      );

      AppLogger.i(
        'SyncOwnerRelayChannel',
        'Synced channel ${targetChannel.channelId} (epoch $epochToUse) to native. Updated: $updated',
      );
      return updated;
    } catch (e, stack) {
      AppLogger.w('SyncOwnerRelayChannel', 'Sync failed with error', e, stack);
      return false;
    }
  }
}
