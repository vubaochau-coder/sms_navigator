import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/device/data/repositories/device_setup_repository.dart';
import '../../features/device/data/services/device_setup_service.dart';
import '../../features/device/data/services/device_api_service.dart';
import '../../features/otp_list/data/repositories/otp_list_repository.dart';
import '../../features/pairing/data/repositories/pairing_repository.dart';
import '../../features/pairing/data/services/pair_management_service.dart';
import '../../features/pairing/data/services/pairing_service.dart';
import '../../features/receiver/data/services/receiver_storage_service.dart';
import '../../features/sender/data/services/native_relay_service.dart';
import '../network/api_client.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/device_storage_service.dart';
import '../services/fcm_notification_service.dart';
import '../storage/local_storage_service.dart';

/// Bootstrap Widget cung cấp toàn bộ Dependency Injection qua cây Widget
/// sử dụng [MultiRepositoryProvider] để làm phẳng cấu trúc lồng nhau.
class AppBootstrap extends StatelessWidget {
  final Widget child;
  final LocalStorageService localStorageService;
  final bool initializeAsyncServices;

  const AppBootstrap({
    super.key,
    required this.child,
    required this.localStorageService,
    this.initializeAsyncServices = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (initializeAsyncServices) {
      content = _AsyncServicesInitializer(child: content);
    }

    return MultiRepositoryProvider(
      providers: [
        // 1. Tầng độc lập: Crashlytics & Analytics
        RepositoryProvider<CrashlyticsService>(
          create: (_) => CrashlyticsService.instance,
        ),
        RepositoryProvider<AnalyticsService>(
          create: (_) => AnalyticsService.instance,
        ),

        // 2. Tầng Platform Native & Local Storage
        RepositoryProvider<LocalStorageService>.value(
          value: localStorageService,
        ),
        RepositoryProvider<NativeRelayService>(
          create: (_) => NativeRelayServiceImpl(),
        ),
        RepositoryProvider<DeviceStorageService>(
          create: (context) =>
              DeviceStorageServiceImpl(context.read<LocalStorageService>()),
        ),
        RepositoryProvider<ReceiverStorageService>(
          create: (context) =>
              ReceiverStorageServiceImpl(context.read<LocalStorageService>()),
        ),

        // 3. Tầng Network (phụ thuộc DeviceStorageService)
        RepositoryProvider<ApiClient>(
          create: (context) {
            final storage = context.read<DeviceStorageService>();
            return ApiClient(
              serverUrlProvider: storage.getServerUrl,
              tokenProvider: storage.getDeviceToken,
            );
          },
        ),
        RepositoryProvider<DeviceApiService>(
          create: (context) => DeviceApiServiceImpl(
            apiClient: context.read<ApiClient>(),
            storageService: context.read<DeviceStorageService>(),
          ),
        ),

        // 4. Tầng Services & Repositories nghiệp vụ
        RepositoryProvider<DeviceSetupRepository>(
          create: (context) => DeviceSetupRepositoryImpl(
            deviceSetupService: DeviceSetupServiceImpl(
              nativeRelayService: context.read<NativeRelayService>(),
              localStorageService: context.read<LocalStorageService>(),
            ),
          ),
        ),
        RepositoryProvider<PairingService>(
          create: (context) => PairingServiceImpl(
            nativeService: context.read<NativeRelayService>(),
            localStorageService: context.read<LocalStorageService>(),
            apiClient: context.read<ApiClient>(),
            deviceApiService: context.read<DeviceApiService>(),
            deviceStorageService: context.read<DeviceStorageService>(),
          ),
        ),
        RepositoryProvider<PairingRepository>(
          create: (context) => PairingRepositoryImpl(
            pairingService: context.read<PairingService>(),
          ),
        ),
        RepositoryProvider<PairManagementService>(
          create: (context) => PairManagementServiceImpl(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        RepositoryProvider<FcmNotificationService>(
          create: (context) => FcmNotificationService(
            deviceStorageService: context.read<DeviceStorageService>(),
            deviceApiService: context.read<DeviceApiService>(),
            receiverStorageService: context.read<ReceiverStorageService>(),
          ),
        ),
        RepositoryProvider<OtpListRepository>(
          create: (context) => OtpListRepositoryImpl(
            apiClient: context.read<ApiClient>(),
            storageService: context.read<DeviceStorageService>(),
            nativeRelayService: context.read<NativeRelayService>(),
            localStorageService: context.read<LocalStorageService>(),
          ),
        ),
      ],
      child: content,
    );
  }
}

/// Khởi tạo các asynchronous services khi cây Widget bắt đầu mount.
class _AsyncServicesInitializer extends StatefulWidget {
  final Widget child;

  const _AsyncServicesInitializer({required this.child});

  @override
  State<_AsyncServicesInitializer> createState() =>
      _AsyncServicesInitializerState();
}

class _AsyncServicesInitializerState extends State<_AsyncServicesInitializer> {
  @override
  void initState() {
    super.initState();
    final crashlytics = context.read<CrashlyticsService>();
    final analytics = context.read<AnalyticsService>();
    final fcm = context.read<FcmNotificationService>();

    crashlytics.initialize();
    analytics.initialize();
    fcm.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
