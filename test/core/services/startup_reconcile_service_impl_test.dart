import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/impls/startup_reconcile_service_impl.dart';
import 'package:sms_navigator/core/usecases/sync_channel_keys_use_case.dart';

class _Keys implements ChannelKeyStore {
  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async =>
      const IdentityKeyPair(privateKeyBase64: 'p', publicKeyBase64: 'q');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Storage implements DeviceStorageService {
  String? token = 'token';

  @override
  Future<String?> getDeviceToken() async => token;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Sync implements SyncChannelKeysUseCase {
  int calls = 0;
  Object? error;

  @override
  Future<ChannelKeySyncResult> call({String? channelId}) async {
    calls++;
    if (error != null) throw error!;
    return const ChannelKeySyncResult(added: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _Storage storage;
  late _Sync sync;
  late DateTime now;
  late StartupReconcileServiceImpl reconcile;

  setUp(() {
    storage = _Storage();
    sync = _Sync();
    now = DateTime(2026, 10, 22, 9);
    reconcile = StartupReconcileServiceImpl(
      deviceStorage: storage,
      keyStore: _Keys(),
      syncChannelKeys: sync,
      clock: () => now,
    );
  });

  test('one key sync (all channels, all epochs) per run', () async {
    await reconcile.reconcile();
    expect(sync.calls, 1);
  });

  test('Splash, home and the channel tab calling at startup share one run (FLOW_AUDIT P1)', () async {
    await Future.wait([reconcile.reconcile(), reconcile.reconcile()]);
    await reconcile.reconcile(); // right after: within minInterval
    expect(sync.calls, 1);

    now = now.add(reconcile.minInterval);
    await reconcile.reconcile();
    expect(sync.calls, 2);
  });

  test('a failed run is retried on the next call', () async {
    sync.error = Exception('offline');
    await reconcile.reconcile();
    sync.error = null;
    await reconcile.reconcile();
    expect(sync.calls, 2);
  });

  test('never registers a device: without a token there is nothing to reconcile (FLOW_AUDIT S1)', () async {
    storage.token = null;
    await reconcile.reconcile();
    expect(sync.calls, 0);
  });
}
