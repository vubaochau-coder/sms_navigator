import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/splash_status.dart';
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

  SplashBloc({
    required this.crashlyticsService,
    required this.analyticsService,
    required this.fcmService,
    required this.deviceStorageService,
    required this.keyStore,
    required this.deviceApiService,
    required this.startupReconcileService,
    TargetPlatform? platform,
  }) : platform = platform ?? defaultTargetPlatform,
       super(const SplashState()) {
    on<SplashStarted>(_onStarted, transformer: droppable());
    on<SplashRetried>(_onRetried, transformer: droppable());
  }

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _onRetried(
    SplashRetried event,
    Emitter<SplashState> emit,
  ) async {
    await _executeBootstrap(
      defaultDeviceName: event.defaultDeviceName,
      emit: emit,
    );
  }

  Future<void> _executeBootstrap({
    required String defaultDeviceName,
    required Emitter<SplashState> emit,
  }) async {
    emit(state.copyWith(
      status: SplashStatus.initializingServices,
      errorMessage: null,
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
        );
      }

      // 5. Đồng bộ FCM token chuông
      try {
        await fcmService.syncToken();
      } catch (e, stack) {
        AppLogger.w('SplashBloc', 'FCM syncToken error', e, stack);
      }

      // 6. Startup reconcile các kênh & quyền truy cập
      emit(state.copyWith(status: SplashStatus.syncingChannels));
      try {
        await startupReconcileService.reconcile();
      } catch (e, stack) {
        AppLogger.w('SplashBloc', 'Startup reconcile error', e, stack);
      }

      emit(state.copyWith(status: SplashStatus.ready));
    } catch (error, stack) {
      AppLogger.e('SplashBloc', 'Bootstrap error', error, stack);
      emit(state.copyWith(
        status: SplashStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }
}
