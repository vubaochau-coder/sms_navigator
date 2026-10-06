import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/splash_status.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/channel_key_store.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../core/services/device_api_service.dart';
import '../../../core/services/device_storage_service.dart';
import '../../../core/services/fcm_notification_service.dart';
import '../../../core/services/startup_reconcile_service.dart';
import '../../../core/utils/app_logger.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final CrashlyticsService crashlyticsService;
  final AnalyticsService analyticsService;
  final FcmNotificationService fcmService;
  final DeviceStorageService deviceStorageService;
  final ChannelKeyStore keyStore;
  final DeviceApiService deviceApiService;
  final StartupReconcileService startupReconcileService;
  final TargetPlatform platform;
  final Duration minDisplayDuration;

  CancelToken? _cancelToken;

  SplashBloc({
    required this.crashlyticsService,
    required this.analyticsService,
    required this.fcmService,
    required this.deviceStorageService,
    required this.keyStore,
    required this.deviceApiService,
    required this.startupReconcileService,
    TargetPlatform? platform,
    this.minDisplayDuration = const Duration(milliseconds: 1200),
  }) : platform = platform ?? defaultTargetPlatform,
       super(const SplashState()) {
    on<SplashStarted>(_onStarted, transformer: droppable());
    on<SplashRetried>(_onRetried, transformer: restartable());
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('SplashBloc closed');
    return super.close();
  }

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    _cancelToken = CancelToken();
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _onRetried(
    SplashRetried event,
    Emitter<SplashState> emit,
  ) async {
    _cancelToken?.cancel('SplashRetried triggered');
    _cancelToken = CancelToken();
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _executeBootstrap({
    required String defaultDeviceName,
    required Emitter<SplashState> emit,
  }) async {
    final stopwatch = Stopwatch()..start();

    emit(state.copyWith(
      status: SplashStatus.initializingServices,
      clearError: true,
    ));

    try {
      // 1. Dịch vụ báo cáo & telemetry
      await crashlyticsService.initialize();
      analyticsService.initialize();

      // 2. Dịch vụ chuông FCM
      fcmService.initialize();

      // 3. Khởi tạo & kiểm tra cặp khóa định danh thiết bị (Identity Key)
      emit(state.copyWith(status: SplashStatus.checkingIdentityKey));
      await keyStore.getOrCreateIdentityKeyPair();

      // 4. Kiểm tra trạng thái đăng ký thiết bị với máy chủ
      emit(state.copyWith(status: SplashStatus.authenticatingDevice));
      final deviceToken = await deviceStorageService.getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) {
        emit(state.copyWith(status: SplashStatus.registeringDevice));
        await deviceApiService.registerDevice(
          deviceName: defaultDeviceName,
          platform: platform == TargetPlatform.iOS ? 'ios' : 'android',
          cancelToken: _cancelToken,
        );
      } else {
        final isValid = await deviceApiService.verifyDeviceToken(
          cancelToken: _cancelToken,
        );
        if (!isValid) {
          AppLogger.w(
            'SplashBloc',
            'Device token không hợp lệ (401), tiến hành đăng ký mới thiết bị',
          );
          await deviceStorageService.clearDeviceToken();
          emit(state.copyWith(status: SplashStatus.registeringDevice));
          await deviceApiService.registerDevice(
            deviceName: defaultDeviceName,
            platform: platform == TargetPlatform.iOS ? 'ios' : 'android',
            cancelToken: _cancelToken,
          );
        }
      }

      // 5. Đồng bộ FCM token chuông (best-effort)
      try {
        await fcmService.syncToken();
      } catch (e, stack) {
        AppLogger.w('SplashBloc', 'FCM syncToken error', e, stack);
        await analyticsService.logEvent(
          'splash_fcm_sync_failed',
          parameters: <String, Object>{'error': e.toString()},
        );
      }

      // 6. Startup reconcile các kênh & quyền truy cập (best-effort)
      emit(state.copyWith(status: SplashStatus.syncingChannels));
      try {
        await startupReconcileService.reconcile();
      } catch (e, stack) {
        AppLogger.w('SplashBloc', 'Startup reconcile error', e, stack);
        await analyticsService.logEvent(
          'splash_reconcile_failed',
          parameters: <String, Object>{'error': e.toString()},
        );
      }

      // 7. Đảm bảo thời gian hiển thị tối thiểu để animation hiển thị chỉn chu
      if (minDisplayDuration > Duration.zero) {
        final elapsed = stopwatch.elapsedMilliseconds;
        final remaining = minDisplayDuration.inMilliseconds - elapsed;
        if (remaining > 0) {
          await Future<void>.delayed(Duration(milliseconds: remaining));
        }
      }

      emit(state.copyWith(status: SplashStatus.ready));
    } on RequestCancelledException {
      AppLogger.d('SplashBloc', 'Bootstrap was cancelled for retry');
    } catch (error, stack) {
      AppLogger.e('SplashBloc', 'Bootstrap error', error, stack);
      await crashlyticsService.recordError(
        error,
        stack,
        reason: 'Bootstrap error',
      );

      final String userFriendlyMessage;
      if (error is NetworkException) {
        userFriendlyMessage = error.message;
      } else if (error is ApiException) {
        userFriendlyMessage =
            'Máy chủ đang gặp sự cố (HTTP ${error.statusCode ?? 'Unknown'}). Vui lòng thử lại sau.';
      } else if (error is StateError) {
        userFriendlyMessage = error.message;
      } else {
        userFriendlyMessage =
            'Đã xảy ra sự cố trong quá trình khởi động hệ thống. Vui lòng thử lại.';
      }

      emit(state.copyWith(
        status: SplashStatus.failure,
        errorMessage: userFriendlyMessage,
      ));
    }
  }
}
