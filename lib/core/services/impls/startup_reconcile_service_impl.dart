import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../enums/pairing_request_status.dart';
import '../../repositories/channel_repository.dart';
import '../../repositories/join_channel_repository.dart';
import '../../utils/app_logger.dart';
import '../../utils/bounded_concurrency.dart';
import '../channel_key_store.dart';
import '../device_api_service.dart';
import '../device_storage_service.dart';
import '../startup_reconcile_service.dart';

typedef DeviceNameProvider = FutureOr<String> Function();

class StartupReconcileServiceImpl implements StartupReconcileService {
  StartupReconcileServiceImpl({
    required DeviceApiService deviceApiService,
    required DeviceStorageService deviceStorage,
    required ChannelKeyStore keyStore,
    required ChannelRepository channelRepository,
    required JoinChannelRepository joinRepository,
    required DeviceNameProvider deviceNameProvider,
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
  final DeviceNameProvider _deviceNameProvider;

  bool _running = false;

  @override
  Future<void> reconcile() async {
    if (_running) return;
    _running = true;
    try {
      await _ensureIdentityAndRegistration();
      final provisioned = await _syncJoinRequests();
      await _provisionChannelKeys(skip: provisioned);
    } catch (error, stack) {
      AppLogger.w(
        'StartupReconcile',
        'Startup reconcile skipped or encountered error',
        error,
        stack,
      );
    } finally {
      _running = false;
    }
  }

  Future<void> _ensureIdentityAndRegistration() async {
    await _keyStore.getOrCreateIdentityKeyPair();

    final deviceToken = await _deviceStorage.getDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) {
      final deviceName = await _deviceNameProvider();
      await _deviceApi.registerDevice(
        deviceName: deviceName,
        platform:
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
    }
  }

  /// Trả về các kênh đã được provision ở bước này để bước sau không làm lại.
  Future<Set<String>> _syncJoinRequests() async {
    final provisioned = <String>{};
    try {
      final requests = await _joinRepository.listMyRequests();
      final approved = requests
          .where((r) => r.status == PairingRequestStatus.approved)
          .toList();
      for (final request in approved) {
        await _joinRepository.provisionLatestForApproved(
          channelId: request.channelId,
        );
        provisioned.add(request.channelId);
      }
    } catch (_) {
      // Không chặn phần còn lại của reconcile
    }
    return provisioned;
  }

  /// BACKLOG 3.4: trước đây mỗi kênh tốn 3 request mỗi lần mở app (detail,
  /// detail lặp lại trong `provisionLatestForApproved`, envelope) kể cả khi
  /// key đã có. Giờ:
  /// - đã có key cho `current_epoch` (lấy từ danh sách kênh) → bỏ qua, 0 request
  ///   (kết quả y như cũ: `provisionChannelKey` cũng sẽ dừng ở đó);
  /// - còn lại gọi thẳng `provisionLatestForApproved` (nó tự kiểm tra
  ///   owner public key), chạy song song tối đa [_concurrency] kênh.
  Future<void> _provisionChannelKeys({Set<String> skip = const {}}) async {
    final channels = await _channelRepository.listChannels();
    final pending = <String>[];
    for (final channel in channels) {
      if (skip.contains(channel.channelId)) continue;
      final existing = await _keyStore.getChannelKey(
        channelId: channel.channelId,
        epoch: channel.currentEpoch,
      );
      if (existing != null && existing.isNotEmpty) continue;
      pending.add(channel.channelId);
    }

    await forEachBounded<String>(
      pending,
      (channelId) async {
        try {
          await _joinRepository.provisionLatestForApproved(channelId: channelId);
        } catch (error) {
          debugPrint('Provision key failed for $channelId: $error');
        }
      },
      concurrency: _concurrency,
    );
  }

  static const int _concurrency = 4;
}
