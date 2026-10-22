import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/services/device_session_recovery.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';

class _Storage implements DeviceStorageService {
  String? token = 'old';

  @override
  Future<String?> getDeviceToken() async => token;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Storage storage;
  late List<String> notices;
  late DateTime now;
  late DeviceSessionRecovery recovery;

  setUp(() {
    storage = _Storage();
    notices = [];
    now = DateTime(2026, 10, 22, 9);
    recovery = DeviceSessionRecovery(storage: storage, clock: () => now, notifyFailure: notices.add);
  });

  test('never re-registers: a 401 is reported and the request is not retried (FLOW_AUDIT S1)', () async {
    expect(await recovery(), isFalse);
    expect(notices, hasLength(1));
  });

  test('repeated 401s are reported once per cooldown', () async {
    await recovery();
    await recovery();
    expect(notices, hasLength(1));

    now = now.add(DeviceSessionRecovery.notifyCooldown);
    await recovery();
    expect(notices, hasLength(2));
  });

  test('never registered → not a session problem, nothing reported', () async {
    storage.token = null;
    expect(await recovery(), isFalse);
    expect(notices, isEmpty);
  });
}
