import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/enums/splash_status.dart';
import 'package:sms_navigator/core/services/analytics_service.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/crashlytics_service.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/fcm_notification_service.dart';
import 'package:sms_navigator/core/services/startup_reconcile_service.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';
import 'package:sms_navigator/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:sms_navigator/features/splash/presentation/bloc/splash_event.dart';

class _FakeCrashlyticsService implements CrashlyticsService {
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAnalyticsService implements AnalyticsService {
  bool initialized = false;

  @override
  void initialize() {
    initialized = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFcmService implements FcmNotificationService {
  bool initialized = false;
  bool synced = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> syncToken() async {
    synced = true;
  }

  @override
  void dispose() {}
}

class _FakeDeviceStorageService implements DeviceStorageService {
  String? deviceToken;

  _FakeDeviceStorageService();

  @override
  Future<String?> getDeviceToken() async => deviceToken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChannelKeyStore implements ChannelKeyStore {
  bool gotIdentityKey = false;

  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async {
    gotIdentityKey = true;
    return const IdentityKeyPair(
      privateKeyBase64: 'priv_key',
      publicKeyBase64: 'pub_key',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceApiService implements DeviceApiService {
  bool registered = false;
  bool shouldThrow = false;

  @override
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
  }) async {
    if (shouldThrow) {
      throw Exception('Network connection timeout');
    }
    registered = true;
    return {'device_id': 'dev_1', 'device_token': 'tok_1'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStartupReconcileService implements StartupReconcileService {
  bool reconciled = false;

  @override
  Future<void> reconcile() async {
    reconciled = true;
  }
}

void main() {
  group('SplashBloc', () {
    late _FakeCrashlyticsService crashlytics;
    late _FakeAnalyticsService analytics;
    late _FakeFcmService fcm;
    late _FakeDeviceStorageService storage;
    late _FakeChannelKeyStore keyStore;
    late _FakeDeviceApiService deviceApi;
    late _FakeStartupReconcileService reconcile;

    setUp(() {
      crashlytics = _FakeCrashlyticsService();
      analytics = _FakeAnalyticsService();
      fcm = _FakeFcmService();
      storage = _FakeDeviceStorageService();
      keyStore = _FakeChannelKeyStore();
      deviceApi = _FakeDeviceApiService();
      reconcile = _FakeStartupReconcileService();
    });

    SplashBloc buildBloc() {
      return SplashBloc(
        crashlyticsService: crashlytics,
        analyticsService: analytics,
        fcmService: fcm,
        deviceStorageService: storage,
        keyStore: keyStore,
        deviceApiService: deviceApi,
        startupReconcileService: reconcile,
        platform: TargetPlatform.android,
      );
    }

    test('initial state has status initial and null error', () {
      final bloc = buildBloc();
      expect(bloc.state.status, SplashStatus.initial);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.isLoading, isTrue);
      expect(bloc.state.isReady, isFalse);
      expect(bloc.state.isFailure, isFalse);
    });

    test('SplashStarted registers device when token is null and completes ready', () async {
      final bloc = buildBloc();

      final states = <SplashStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));

      bloc.add(const SplashStarted(defaultDeviceName: 'Test Phone'));
      await pumpEventQueue();

      expect(crashlytics.initialized, isTrue);
      expect(analytics.initialized, isTrue);
      expect(fcm.initialized, isTrue);
      expect(keyStore.gotIdentityKey, isTrue);
      expect(deviceApi.registered, isTrue);
      expect(fcm.synced, isTrue);
      expect(reconcile.reconciled, isTrue);

      expect(states, containsAllInOrder([
        SplashStatus.initializingServices,
        SplashStatus.checkingIdentityKey,
        SplashStatus.authenticatingDevice,
        SplashStatus.registeringDevice,
        SplashStatus.syncingChannels,
        SplashStatus.ready,
      ]));
      expect(bloc.state.isReady, isTrue);

      await sub.cancel();
      await bloc.close();
    });

    test('SplashStarted skips register when token already exists', () async {
      storage.deviceToken = 'existing_device_token';
      final bloc = buildBloc();

      final states = <SplashStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));

      bloc.add(const SplashStarted());
      await pumpEventQueue();

      expect(deviceApi.registered, isFalse);
      expect(states, isNot(contains(SplashStatus.registeringDevice)));
      expect(states.last, SplashStatus.ready);

      await sub.cancel();
      await bloc.close();
    });

    test('SplashStarted emits failure when device API throws', () async {
      deviceApi.shouldThrow = true;
      final bloc = buildBloc();

      final states = <SplashStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));

      bloc.add(const SplashStarted());
      await pumpEventQueue();

      expect(bloc.state.isFailure, isTrue);
      expect(bloc.state.status, SplashStatus.failure);
      expect(bloc.state.errorMessage, contains('Network connection timeout'));

      await sub.cancel();
      await bloc.close();
    });

    test('SplashRetried executes bootstrap again after failure', () async {
      deviceApi.shouldThrow = true;
      final bloc = buildBloc();

      bloc.add(const SplashStarted());
      await pumpEventQueue();
      expect(bloc.state.isFailure, isTrue);

      // Now fix network and retry
      deviceApi.shouldThrow = false;
      bloc.add(const SplashRetried());
      await pumpEventQueue();

      expect(bloc.state.isReady, isTrue);
      expect(bloc.state.errorMessage, isNull);

      await bloc.close();
    });
  });
}
