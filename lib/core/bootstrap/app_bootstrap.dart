import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_client.dart';
import '../repositories/app_update_repository.dart';
import '../repositories/channel_repository.dart';
import '../repositories/device_setup_repository.dart';
import '../repositories/impls/app_update_repository_impl.dart';
import '../repositories/impls/channel_repository_impl.dart';
import '../repositories/impls/device_setup_repository_impl.dart';
import '../repositories/impls/join_channel_repository_impl.dart';
import '../repositories/impls/sms_by_date_repository_impl.dart';
import '../repositories/impls/whitelist_repository_impl.dart';
import '../repositories/join_channel_repository.dart';
import '../repositories/sms_by_date_repository.dart';
import '../repositories/whitelist_repository.dart';
import '../services/analytics_service.dart';
import '../services/app_update_service.dart';
import '../services/channel_api_service.dart';
import '../services/channel_key_store.dart';
import '../services/crashlytics_service.dart';
import '../services/device_api_service.dart';
import '../services/device_storage_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/impls/app_update_service_impl.dart';
import '../services/impls/channel_api_service_impl.dart';
import '../services/impls/channel_key_store_impl.dart';
import '../services/impls/device_api_service_impl.dart';
import '../services/impls/device_setup_service_impl.dart';
import '../services/impls/device_storage_service_impl.dart';
import '../services/impls/fcm_notification_service_impl.dart';
import '../services/impls/message_api_service_impl.dart';
import '../services/impls/native_relay_service_impl.dart';
import '../services/impls/pairing_api_service_impl.dart';
import '../services/impls/startup_reconcile_service_impl.dart';
import '../services/local_storage_service.dart';
import '../services/message_api_service.dart';
import '../services/native_relay_service.dart';
import '../services/pairing_api_service.dart';
import '../services/startup_reconcile_service.dart';
import '../services/sync_owner_relay_channel_use_case.dart';
import '../theme/theme_cubit.dart';
import '../utils/channel_crypto_helper.dart';
import '../../features/device/bloc/device_profile_cubit.dart';

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
        RepositoryProvider<AppUpdateService>(
          create: (context) => AppUpdateServiceImpl(
            localStorage: context.read<LocalStorageService>(),
          ),
        ),
        RepositoryProvider<NativeRelayService>(
          create: (_) => NativeRelayServiceImpl(),
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
        RepositoryProvider<AppUpdateRepository>(
          create: (context) => AppUpdateRepositoryImpl(
            appUpdateService: context.read<AppUpdateService>(),
          ),
        ),

        // 6. FCM chuông (API spec §7)
        RepositoryProvider<FcmNotificationService>(
          create: (context) => FcmNotificationServiceImpl(
            deviceStorageService: context.read<DeviceStorageService>(),
            deviceApiService: context.read<DeviceApiService>(),
          ),
        ),

        // 7. Channel E2EE (API spec v1.5)
        RepositoryProvider<ChannelApiService>(
          create: (context) =>
              ChannelApiServiceImpl(apiClient: context.read<ApiClient>()),
        ),
        RepositoryProvider<PairingApiService>(
          create: (context) =>
              PairingApiServiceImpl(apiClient: context.read<ApiClient>()),
        ),
        RepositoryProvider<MessageApiService>(
          create: (context) =>
              MessageApiServiceImpl(apiClient: context.read<ApiClient>()),
        ),
        RepositoryProvider<ChannelRepository>(
          create: (context) => ChannelRepositoryImpl(
            channelApiService: context.read<ChannelApiService>(),
            pairingApiService: context.read<PairingApiService>(),
            deviceApiService: context.read<DeviceApiService>(),
            keyStore: context.read<ChannelKeyStore>(),
            cryptoHelper: context.read<ChannelCryptoHelper>(),
            deviceStorage: context.read<DeviceStorageService>(),
          ),
        ),
        RepositoryProvider<JoinChannelRepository>(
          create: (context) => JoinChannelRepositoryImpl(
            channelApiService: context.read<ChannelApiService>(),
            pairingApiService: context.read<PairingApiService>(),
            keyStore: context.read<ChannelKeyStore>(),
            cryptoHelper: context.read<ChannelCryptoHelper>(),
            deviceStorage: context.read<DeviceStorageService>(),
          ),
        ),
        RepositoryProvider<SmsByDateRepository>(
          create: (context) => SmsByDateRepositoryImpl(
            messageApiService: context.read<MessageApiService>(),
            keyStore: context.read<ChannelKeyStore>(),
            cryptoHelper: context.read<ChannelCryptoHelper>(),
          ),
        ),
        RepositoryProvider<StartupReconcileService>(
          create: (context) => StartupReconcileServiceImpl(
            deviceApiService: context.read<DeviceApiService>(),
            deviceStorage: context.read<DeviceStorageService>(),
            keyStore: context.read<ChannelKeyStore>(),
            channelRepository: context.read<ChannelRepository>(),
            joinRepository: context.read<JoinChannelRepository>(),
            deviceNameProvider: () async {
              try {
                final nativeName =
                    await context.read<NativeRelayService>().getDeviceName();
                if (nativeName != null && nativeName.trim().isNotEmpty) {
                  return nativeName.trim();
                }
              } catch (_) {}
              return 'Thiết bị của tôi';
            },
          ),
        ),

        // 8. Settings (SMS whitelist — giữ nguyên hạ tầng native 7.2)
        RepositoryProvider<WhitelistRepository>(
          create: (context) => WhitelistRepositoryImpl(
            nativeRelayService: context.read<NativeRelayService>(),
          ),
        ),

        // 9. Relay V2 Sync (Đồng bộ khóa Owner xuống Native)
        RepositoryProvider<SyncOwnerRelayChannelUseCase>(
          create: (context) => SyncOwnerRelayChannelUseCase(
            channelRepository: context.read<ChannelRepository>(),
            keyStore: context.read<ChannelKeyStore>(),
            deviceStorage: context.read<DeviceStorageService>(),
            nativeRelayService: context.read<NativeRelayService>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit(
              localStorage: context.read<LocalStorageService>(),
            ),
          ),
          BlocProvider<DeviceProfileCubit>(
            create: (context) => DeviceProfileCubit(
              deviceStorage: context.read<DeviceStorageService>(),
              channelRepository: context.read<ChannelRepository>(),
              nativeRelayService: context.read<NativeRelayService>(),
            )..loadDeviceProfile(),
          ),
        ],
        child: content,
      ),
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
    final syncRelay = context.read<SyncOwnerRelayChannelUseCase>();

    crashlytics.initialize();
    analytics.initialize();
    fcm.initialize();
    fcm.syncToken();
    fcm.setChannelEventListener(() {
      syncRelay().catchError((_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
