import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/impls/startup_repository_impl.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/channel_key_store.dart';
import '../../core/services/crashlytics_service.dart';
import '../../core/services/device_api_service.dart';
import '../../core/services/device_storage_service.dart';
import '../../core/services/fcm_notification_service.dart';
import '../../core/services/native_relay_service.dart';
import '../../core/services/startup_gate.dart';
import '../../core/services/startup_reconcile_service.dart';
import 'bloc/splash_bloc.dart';
import 'bloc/splash_event.dart';
import 'views/splash_view.dart';

export 'views/splash_branding_view.dart';
export 'views/splash_error_view.dart';
export 'views/splash_progress_view.dart';
export 'views/splash_setup_choice_view.dart';
export 'views/splash_view.dart';

/// Màn hình Splash / Khởi tạo & Kiểm tra đăng ký thiết bị theo kiến trúc BLoC.
class SplashPage extends StatelessWidget {
  final bool autoStart;
  final VoidCallback? onCompleted;

  const SplashPage({
    super.key,
    this.autoStart = true,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final defaultDeviceName = context.l10n.splashDefaultDeviceName;

    return BlocProvider(
      create: (ctx) {
        final bloc = SplashBloc(
          startupRepository: StartupRepositoryImpl(
            crashlyticsService: ctx.read<CrashlyticsService>(),
            analyticsService: ctx.read<AnalyticsService>(),
            fcmService: ctx.read<FcmNotificationService>(),
            deviceStorageService: ctx.read<DeviceStorageService>(),
            keyStore: ctx.read<ChannelKeyStore>(),
            deviceApiService: ctx.read<DeviceApiService>(),
            startupReconcileService: ctx.read<StartupReconcileService>(),
            nativeRelayService: ctx.read<NativeRelayService>(),
            startupGate: ctx.read<StartupGate>(),
          ),
          offerRestoreOnFirstRun: true,
        );
        if (autoStart) {
          bloc.add(SplashStarted(
            defaultDeviceName: defaultDeviceName,
          ));
        }
        return bloc;
      },
      child: SplashView(onCompleted: onCompleted),
    );
  }
}
