import 'package:flutter/foundation.dart';

import '../../../../core/services/device_storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../device/data/services/device_api_service.dart';
import 'channel_key_store.dart';
import '../../data/models/pairing_request_model.dart';
import '../repositories/channel_repository.dart';
import '../repositories/join_channel_repository.dart';

/// Reconcile lúc mở app (SRD 7.3) — hành vi ngầm, không có màn hình riêng:
/// 1. Đảm bảo identity key + thiết bị đã đăng ký (feature 1.1);
/// 2. Channel state: với mỗi kênh đang ACTIVE → provision envelope mới nhất
///    nếu thiếu (fetch key-envelope latest → unwrap → persist);
/// 3. Request state: join request APPROVED chưa provision → provision ngay;
/// 4. REVOKED (server loại kênh khỏi danh sách) → purge key material (KL12).
class StartupReconcileService {
  StartupReconcileService({
    required DeviceApiService deviceApiService,
    required DeviceStorageService deviceStorage,
    required ChannelKeyStore keyStore,
    required ChannelRepository channelRepository,
    required JoinChannelRepository joinRepository,
    required String Function() deviceNameProvider,
  }) : _deviceApi = deviceApiService,
       _deviceStorage = deviceStorage,
       _keyStore = keyStore,
       _channelRepository = channelRepository,
       _joinRepository = joinRepository,
       _deviceNameProvider = deviceNameProvider;

  final DeviceApiService _deviceApi;
  final DeviceStorageService _deviceStorage;
  final ChannelKeyStore _keyStore;
  final ChannelRepository _channelRepository;
  final JoinChannelRepository _joinRepository;
  final String Function() _deviceNameProvider;

  bool _running = false;

  Future<void> reconcile() async {
    if (_running) return;
    _running = true;
    try {
      await _ensureIdentityAndRegistration();
      await _syncJoinRequests();
      await _provisionChannelKeys();
    } catch (error, stack) {
      // Reconcile là hành vi ngầm — lỗi không phá UI (FCM/network tạm lỗi
      // sẽ được retry ở lần mở app kế tiếp), nhưng ghi nhận vào Crashlytics.
      AppLogger.w('StartupReconcile', 'Startup reconcile skipped or encountered error', error, stack);
    } finally {
      _running = false;
    }
  }

  Future<void> _ensureIdentityAndRegistration() async {
    // Identity key được sinh lazy trong ChannelKeyStore.getOrCreateIdentityKeyPair
    await _keyStore.getOrCreateIdentityKeyPair();

    final deviceToken = await _deviceStorage.getDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) {
      await _deviceApi.registerDevice(
        deviceName: _deviceNameProvider(),
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
    }
  }

  Future<void> _syncJoinRequests() async {
    try {
      final requests = await _joinRepository.listMyRequests();
      final approved = requests
          .where((r) => r.status == PairingRequestStatus.approved)
          .toList();
      for (final request in approved) {
        await _joinRepository.provisionLatestForApproved(
          channelId: request.channelId,
        );
      }
    } catch (_) {
      // Không chặn phần còn lại của reconcile
    }
  }

  Future<void> _provisionChannelKeys() async {
    final channels = await _channelRepository.listChannels();
    for (final channel in channels) {
      try {
        final detail = await _channelRepository.getChannelDetail(channel.channelId);
        if (detail.ownerPublicKey.isEmpty) continue;
        // Idempotent: envelope đã provision thì repository tự bỏ qua.
        await _joinRepository.provisionLatestForApproved(
          channelId: channel.channelId,
        );
      } catch (error) {
        debugPrint('Provision key failed for ${channel.channelId}: $error');
      }
    }
  }
}
