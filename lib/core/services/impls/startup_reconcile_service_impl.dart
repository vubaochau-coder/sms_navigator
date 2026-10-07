import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../enums/pairing_request_status.dart';
import '../../repositories/channel_repository.dart';
import '../../repositories/join_channel_repository.dart';
import '../../utils/app_logger.dart';
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
      await _syncJoinRequests();
      await _provisionChannelKeys();
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
        final detail = await _channelRepository.getChannelDetail(
          channel.channelId,
        );
        if (detail.ownerPublicKey.isEmpty) continue;
        await _joinRepository.provisionLatestForApproved(
          channelId: channel.channelId,
        );
      } catch (error) {
        debugPrint('Provision key failed for ${channel.channelId}: $error');
      }
    }
  }
}
