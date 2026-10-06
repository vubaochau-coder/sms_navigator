import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/enums/splash_status.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/services/analytics_service.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/crashlytics_service.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/fcm_notification_service.dart';
import 'package:sms_navigator/core/services/startup_reconcile_service.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';
import 'package:sms_navigator/features/splash/bloc/splash_bloc.dart';
import 'package:sms_navigator/features/splash/bloc/splash_event.dart';

class _FakeCrashlyticsService implements CrashlyticsService {
  bool initialized = false;
  final List<dynamic> recordedErrors = [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    recordedErrors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAnalyticsService implements AnalyticsService {
  bool initialized = false;
  final List<String> loggedEvents = [];

  @override
  void initialize() {
    initialized = true;
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    loggedEvents.add(name);
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
  Future<void> clearDeviceToken() async {
    deviceToken = null;
  }

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
  bool tokenValid = true;
  bool verifyShouldThrow = false;

  @override
  Future<bool> verifyDeviceToken({CancelToken? cancelToken}) async {
    if (verifyShouldThrow) {
      throw const NetworkException('Network connection timeout');
    }
    return tokenValid;
  }

  @override
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
    CancelToken? cancelToken,
  }) async {
    if (shouldThrow) {
      throw const NetworkException('Network connection timeout');
    }
    registered = true;
    return {'device_id': 'dev_1', 'device_token': 'tok_1'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStartupReconcileService implements StartupReconcileService {
  bool reconciled = false;
  bool shouldThrow = false;

  @override
  Future<void> reconcile() async {
    if (shouldThrow) {
      throw Exception('Reconcile sync error');
    }
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
        minDisplayDuration: Duration.zero,
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

    test('SplashStarted re-registers device when token is invalid (401)', () async {
      storage.deviceToken = 'invalid_device_token';
      deviceApi.tokenValid = false;
      final bloc = buildBloc();

      final states = <SplashStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));

      bloc.add(const SplashStarted());
      await pumpEventQueue();

      expect(deviceApi.registered, isTrue);
      expect(states, contains(SplashStatus.registeringDevice));
      expect(states.last, SplashStatus.ready);

      await sub.cancel();
      await bloc.close();
    });

    test('SplashStarted blocks and emits failure when token verification fails due to network error', () async {
      storage.deviceToken = 'any_token';
      deviceApi.verifyShouldThrow = true;
      final bloc = buildBloc();

      final states = <SplashStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));

      bloc.add(const SplashStarted());
      await pumpEventQueue();

      expect(bloc.state.isFailure, isTrue);
      expect(bloc.state.status, SplashStatus.failure);
      expect(bloc.state.errorMessage, contains('Network connection timeout'));
      expect(states, isNot(contains(SplashStatus.ready)));

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
      expect(crashlytics.recordedErrors, isNotEmpty);

      await sub.cancel();
      await bloc.close();
    });

    test('SplashStarted logs analytics event when startup reconcile throws', () async {
      reconcile.shouldThrow = true;
      final bloc = buildBloc();

      bloc.add(const SplashStarted());
      await pumpEventQueue();

      expect(analytics.loggedEvents, contains('splash_reconcile_failed'));
      expect(bloc.state.isReady, isTrue);

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
