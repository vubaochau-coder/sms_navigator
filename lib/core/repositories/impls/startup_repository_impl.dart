import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../enums/splash_status.dart';
import '../../services/analytics_service.dart';
import '../../services/channel_key_store.dart';
import '../../services/crashlytics_service.dart';
import '../../services/device_api_service.dart';
import '../../services/device_storage_service.dart';
import '../../services/fcm_notification_service.dart';
import '../../services/native_relay_service.dart';
import '../../services/startup_gate.dart';
import '../../services/startup_reconcile_service.dart';
import '../../utils/app_logger.dart';
import '../startup_repository.dart';

class StartupRepositoryImpl implements StartupRepository {
  StartupRepositoryImpl({
    required this.crashlyticsService,
    required this.analyticsService,
    required this.fcmService,
    required this.deviceStorageService,
    required this.keyStore,
    required this.deviceApiService,
    required this.startupReconcileService,
    this.nativeRelayService,
    this.startupGate,
    TargetPlatform? platform,
  }) : platform = platform ?? defaultTargetPlatform;

  final CrashlyticsService crashlyticsService;
  final AnalyticsService analyticsService;
  final FcmNotificationService fcmService;
  final DeviceStorageService deviceStorageService;
  final ChannelKeyStore keyStore;
  final DeviceApiService deviceApiService;
  final StartupReconcileService startupReconcileService;
  final NativeRelayService? nativeRelayService;

  /// Cổng bảo trì (BACKLOG 3.5); null → bỏ qua.
  final StartupGate? startupGate;
  final TargetPlatform platform;

  String get _platformName => platform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Stream<SplashStatus> bootstrap({
    required String defaultDeviceName,
    required bool offerSetupChoice,
    CancelToken? cancelToken,
  }) async* {
    yield SplashStatus.initializingServices;

    // 1. Dịch vụ báo cáo & telemetry
    await crashlyticsService.initialize();
    analyticsService.initialize();

    // 2. Dịch vụ chuông FCM
    await fcmService.initialize();

    // 2b. Cổng khởi động từ xa (bảo trì) — fail-open, trước mọi gọi API
    final gate = await startupGate?.check();
    if (gate != null && gate.blocked) {
      throw StartupBlockedException(gate.message);
    }

    // 3. Khởi tạo & kiểm tra cặp khóa định danh thiết bị (Identity Key)
    yield SplashStatus.checkingIdentityKey;
    await keyStore.getOrCreateIdentityKeyPair();

    // 4. Kiểm tra trạng thái đăng ký thiết bị với máy chủ
    yield SplashStatus.authenticatingDevice;
    final deviceToken = await deviceStorageService.getDeviceToken();
    if (deviceToken == null || deviceToken.isEmpty) {
      if (offerSetupChoice) {
        yield SplashStatus.awaitingSetupChoice;
        return;
      }
      final resolvedName = await _resolveDeviceName(defaultDeviceName);
      yield SplashStatus.registeringDevice;
      await deviceApiService.registerDevice(
        deviceName: resolvedName,
        platform: _platformName,
        cancelToken: cancelToken,
      );
    } else {
      final isValid = await deviceApiService.verifyDeviceToken(cancelToken: cancelToken);
      if (!isValid) {
        // 401: server không còn nhận token này. KHÔNG đăng ký lại cùng
        // device_id (server từ chối — 409 DEVICE_EXISTS, FLOW_AUDIT S1). Bỏ
        // token cũ rồi cho người dùng chọn: khôi phục từ bản sao lưu, hoặc
        // thiết lập như máy mới (device_id mới, phải tham gia lại kênh).
        AppLogger.w('StartupRepository', 'Device token không hợp lệ (401) — cần khôi phục hoặc thiết lập lại');
        await deviceStorageService.clearDeviceToken();
        if (offerSetupChoice) {
          yield SplashStatus.awaitingSetupChoice;
          return;
        }
        final resolvedName = await _resolveDeviceName(defaultDeviceName);
        yield SplashStatus.registeringDevice;
        await deviceApiService.registerDevice(
          deviceName: resolvedName,
          platform: _platformName,
          cancelToken: cancelToken,
        );
      } else {
        // Auto-heal: Nếu tên hiện tại đang là fallback mặc định ("Thiết bị của tôi"),
        // thử tự động đồng bộ tên thật từ hệ thống native.
        await _tryAutoHealDeviceName(defaultDeviceName);
      }
    }

    // 5. Đồng bộ FCM token chuông (best-effort)
    try {
      await fcmService.syncToken();
    } catch (e, stack) {
      AppLogger.w('StartupRepository', 'FCM syncToken error', e, stack);
      await analyticsService.logEvent(
        'splash_fcm_sync_failed',
        parameters: <String, Object>{'error': e.toString()},
      );
    }

    // 6. Startup reconcile các kênh & quyền truy cập (best-effort)
    yield SplashStatus.syncingChannels;
    try {
      await startupReconcileService.reconcile();
    } catch (e, stack) {
      AppLogger.w('StartupRepository', 'Startup reconcile error', e, stack);
      await analyticsService.logEvent(
        'splash_reconcile_failed',
        parameters: <String, Object>{'error': e.toString()},
      );
    }

    yield SplashStatus.ready;
  }

  @override
  Future<void> recordFailure(Object error, StackTrace stack) =>
      crashlyticsService.recordError(error, stack, reason: 'Bootstrap error');

  Future<String> _resolveDeviceName(String fallbackName) async {
    try {
      final nativeName = await nativeRelayService?.getDeviceName();
      if (nativeName != null && nativeName.trim().isNotEmpty) {
        return nativeName.trim();
      }
    } catch (e) {
      AppLogger.w('StartupRepository', 'Lỗi khi lấy tên thiết bị từ native', e);
    }
    return fallbackName;
  }

  Future<void> _tryAutoHealDeviceName(String defaultFallbackName) async {
    try {
      final currentName = await deviceStorageService.getDeviceName();
      final isDefaultOrEmpty =
          currentName == null || currentName.trim().isEmpty || currentName.trim() == defaultFallbackName;

      if (isDefaultOrEmpty) {
        final nativeName = await nativeRelayService?.getDeviceName();
        if (nativeName != null && nativeName.trim().isNotEmpty && nativeName.trim() != defaultFallbackName) {
          final trimmed = nativeName.trim();
          await deviceApiService.updateDeviceName(trimmed);
          AppLogger.i('StartupRepository', 'Tự động cập nhật tên thiết bị thành: $trimmed');
        }
      }
    } catch (e) {
      AppLogger.w('StartupRepository', 'Không thể tự động đồng bộ tên thiết bị', e);
    }
  }
}
