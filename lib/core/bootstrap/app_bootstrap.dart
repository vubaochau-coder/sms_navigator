import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/channel/data/repositories/channel_repository.dart';
import '../../features/channel/data/repositories/join_channel_repository.dart';
import '../../features/channel/data/repositories/sms_by_date_repository.dart';
import '../../features/channel/data/services/channel_api_client.dart';
import '../../features/channel/data/services/channel_key_store.dart';
import '../../features/channel/data/services/startup_reconcile_service.dart';
import '../../features/device/data/repositories/device_setup_repository.dart';
import '../../features/device/data/services/device_api_service.dart';
import '../../features/device/data/services/device_setup_service.dart';
import '../../features/sender/data/services/native_relay_service.dart';
import '../../features/settings/data/repositories/whitelist_repository.dart';
import '../network/api_client.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/deep_link_service.dart';
import '../services/device_storage_service.dart';
import '../services/fcm_notification_service.dart';
import '../storage/local_storage_service.dart';
import '../utils/channel_crypto_helper.dart';

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
    this.initializeAsyncServices = false,
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
        RepositoryProvider<DeepLinkService>(
          create: (_) => DeepLinkService(),
        ),
        RepositoryProvider<DeviceStorageService>(
          create: (context) =>
              DeviceStorageServiceImpl(context.read<LocalStorageService>()),
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

        // 4. Crypto & Key store (SRD 3.1/8.4 — SecureVault)
        RepositoryProvider<ChannelCryptoHelper>(
          create: (_) => ChannelCryptoHelper(),
        ),
        RepositoryProvider<ChannelKeyStore>(
          create: (context) => ChannelKeyStoreImpl(
            cryptoHelper: context.read<ChannelCryptoHelper>(),
          ),
        ),

        // 5. Device (register v2 + setup checklist)
        RepositoryProvider<DeviceApiService>(
          create: (context) => DeviceApiServiceImpl(
            apiClient: context.read<ApiClient>(),
            storageService: context.read<DeviceStorageService>(),
            publicKeyProvider: () async =>
                (await context.read<ChannelKeyStore>().getOrCreateIdentityKeyPair())
                    .publicKeyBase64,
          ),
        ),
        RepositoryProvider<DeviceSetupRepository>(
          create: (context) => DeviceSetupRepositoryImpl(
            deviceSetupService: DeviceSetupServiceImpl(
              nativeRelayService: context.read<NativeRelayService>(),
              localStorageService: context.read<LocalStorageService>(),
            ),
          ),
        ),

        // 6. FCM chuông (API spec §7)
        RepositoryProvider<FcmNotificationService>(
          create: (context) => FcmNotificationService(
            deviceStorageService: context.read<DeviceStorageService>(),
            deviceApiService: context.read<DeviceApiService>(),
          ),
        ),

        // 7. Channel E2EE (API spec v1.5)
        RepositoryProvider<ChannelApiClient>(
          create: (context) =>
              ChannelApiClient(apiClient: context.read<ApiClient>()),
        ),
        RepositoryProvider<ChannelRepository>(
          create: (context) => ChannelRepository(
            apiClient: context.read<ChannelApiClient>(),
            keyStore: context.read<ChannelKeyStore>(),
            cryptoHelper: context.read<ChannelCryptoHelper>(),
            deviceStorage: context.read<DeviceStorageService>(),
          ),
        ),
        RepositoryProvider<JoinChannelRepository>(
          create: (context) => JoinChannelRepository(
            apiClient: context.read<ChannelApiClient>(),
            keyStore: context.read<ChannelKeyStore>(),
            cryptoHelper: context.read<ChannelCryptoHelper>(),
            deviceStorage: context.read<DeviceStorageService>(),
          ),
        ),
        RepositoryProvider<SmsByDateRepository>(
          create: (context) => SmsByDateRepository(
            apiClient: context.read<ChannelApiClient>(),
            keyStore: context.read<ChannelKeyStore>(),
            cryptoHelper: context.read<ChannelCryptoHelper>(),
          ),
        ),
        RepositoryProvider<StartupReconcileService>(
          create: (context) => StartupReconcileService(
            deviceApiService: context.read<DeviceApiService>(),
            deviceStorage: context.read<DeviceStorageService>(),
            keyStore: context.read<ChannelKeyStore>(),
            channelRepository: context.read<ChannelRepository>(),
            joinRepository: context.read<JoinChannelRepository>(),
            deviceNameProvider: () => 'Thiết bị của tôi',
          ),
        ),

        // 8. Settings (SMS whitelist — giữ nguyên hạ tầng native 7.2)
        RepositoryProvider<WhitelistRepository>(
          create: (context) => WhitelistRepositoryImpl(
            nativeRelayService: context.read<NativeRelayService>(),
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
    fcm.syncToken();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
