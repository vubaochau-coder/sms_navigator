import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/device_session_recovery.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/relay_channel_bridge.dart';

class _Storage implements DeviceStorageService {
  String? token = 'old';
  String? id = 'dev-1';

  @override
  Future<String?> getDeviceToken() async => token;
  @override
  Future<String?> getDeviceId() async => id;
  @override
  Future<String?> getDeviceName() async => 'Pixel';
  @override
  Future<String?> getServerUrl() async => 'https://relay.test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DeviceApi implements DeviceApiService {
  _DeviceApi(this.storage);
  final _Storage storage;
  int registers = 0;
  Object? error;
  Completer<void>? gate;

  @override
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
    CancelToken? cancelToken,
  }) async {
    registers++;
    await gate?.future;
    if (error != null) throw error!;
    storage.token = 'new-$registers';
    return {'device_id': storage.id};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bridge implements RelayChannelBridge {
  final List<String> tokens = [];

  @override
  Future<void> setCredentials({required String deviceToken, String? apiBaseUrl}) async => tokens.add(deviceToken);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Storage storage;
  late _DeviceApi api;
  late _Bridge bridge;
  late List<String> failures;
  late DateTime now;
  late DeviceSessionRecovery recovery;

  setUp(() {
    storage = _Storage();
    api = _DeviceApi(storage);
    bridge = _Bridge();
    failures = [];
    now = DateTime(2026, 10, 22, 9);
    recovery = DeviceSessionRecovery(
      deviceApi: api,
      storage: storage,
      relayBridge: bridge,
      clock: () => now,
      notifyFailure: failures.add,
    );
  });

  test('re-registers the same device and pushes the new token to native', () async {
    expect(await recovery(), isTrue);
    expect(api.registers, 1);
    expect(bridge.tokens, ['new-1']);
    expect(failures, isEmpty);
  });

  test('concurrent 401s share one re-registration', () async {
    api.gate = Completer<void>();
    final a = recovery();
    final b = recovery();
    api.gate!.complete();
    expect(await Future.wait([a, b]), [true, true]);
    expect(api.registers, 1);
  });

  test('never registered → not a session problem, nothing happens', () async {
    storage.token = null;
    expect(await recovery(), isFalse);
    expect(api.registers, 0);
    expect(failures, isEmpty);
  });

  test('a failure warns once and backs off for 30 s', () async {
    api.error = Exception('offline');
    expect(await recovery(), isFalse);
    expect(failures, hasLength(1));

    expect(await recovery(), isFalse); // cooling down
    expect(api.registers, 1);

    now = now.add(DeviceSessionRecovery.failureCooldown);
    api.error = null;
    expect(await recovery(), isTrue);
    expect(api.registers, 2);
  });
}
