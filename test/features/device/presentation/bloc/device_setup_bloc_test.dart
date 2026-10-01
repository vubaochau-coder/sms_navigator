import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/device/data/repositories/device_setup_repository.dart';
import 'package:sms_navigator/features/device/presentation/bloc/device_setup_bloc.dart';
import 'package:sms_navigator/features/device/presentation/bloc/device_setup_event.dart';
import 'package:sms_navigator/features/device/presentation/bloc/device_setup_state.dart';

class _FakeDeviceSetupRepository implements DeviceSetupRepository {
  _FakeDeviceSetupRepository({
    this.smsGranted = false,
    this.smsPermanentlyDenied = false,
    this.batteryIgnored = false,
    this.isAggressiveRom = false,
    this.oemName,
    this.autostartAcknowledged = false,
    this.smsRequestResult = false,
    this.batteryRequestResult = false,
  });

  bool smsGranted;
  bool smsPermanentlyDenied;
  bool batteryIgnored;
  bool isAggressiveRom;
  String? oemName;
  bool autostartAcknowledged;
  bool smsRequestResult;
  bool batteryRequestResult;

  int autostartOpenCallCount = 0;
  int autostartAckCallCount = 0;

  @override
  Future<bool> acknowledgeAutostart() async {
    autostartAckCallCount++;
    autostartAcknowledged = true;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async =>
      {'isAggressive': isAggressiveRom, 'oem': oemName};

  @override
  Future<bool> isAutostartAcknowledged() async => autostartAcknowledged;

  @override
  Future<bool> isBatteryOptimizationIgnored() async => batteryIgnored;

  @override
  Future<bool> isSmsPermissionGranted() async => smsGranted;

  @override
  Future<bool> isSmsPermissionPermanentlyDenied() async =>
      smsPermanentlyDenied;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openAutostartSettings() async {
    autostartOpenCallCount++;
    return true;
  }

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (batteryRequestResult) batteryIgnored = true;
    return batteryRequestResult;
  }

  @override
  Future<bool> requestSmsPermission() async {
    if (smsRequestResult) smsGranted = true;
    return smsRequestResult;
  }
}

Future<List<DeviceSetupState>> _collectUntil(
  DeviceSetupBloc bloc,
  bool Function(DeviceSetupState) predicate,
) async {
  final states = <DeviceSetupState>[];
  final done = Completer<void>();
  late final StreamSubscription<DeviceSetupState> subscription;
  subscription = bloc.stream.listen((state) {
    states.add(state);
    if (predicate(state) && !done.isCompleted) {
      done.complete();
    }
  });
  await done.future.timeout(const Duration(seconds: 5));
  await subscription.cancel();
  return states;
}

void main() {
  test('started emits all statuses from repository', () async {
    final bloc = DeviceSetupBloc(
      repository: _FakeDeviceSetupRepository(
        smsGranted: true,
        batteryIgnored: true,
        isAggressiveRom: true,
        oemName: 'xiaomi',
        autostartAcknowledged: true,
      ),
    );

    final statesFuture = _collectUntil(
      bloc,
      (state) => !state.isLoading,
    );
    bloc.add(const DeviceSetupStarted());

    final states = await statesFuture;
    await bloc.close();

    expect(states.first.isLoading, isTrue);
    expect(states.last.smsPermissionGranted, isTrue);
    expect(states.last.batteryUnrestricted, isTrue);
    expect(states.last.isAggressiveRom, isTrue);
    expect(states.last.oemName, 'xiaomi');
    expect(states.last.autostartAcknowledged, isTrue);
  });

  test('started on non-aggressive rom keeps steps hidden flags', () async {
    final bloc = DeviceSetupBloc(repository: _FakeDeviceSetupRepository());

    final statesFuture = _collectUntil(
      bloc,
      (state) => !state.isLoading,
    );
    bloc.add(const DeviceSetupStarted());

    final states = await statesFuture;
    await bloc.close();

    expect(states.last.isAggressiveRom, isFalse);
    expect(states.last.oemName, isNull);
  });

  test('requestSmsPermission updates granted flag on success', () async {
    final bloc = DeviceSetupBloc(
      repository: _FakeDeviceSetupRepository(smsRequestResult: true),
    );

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.smsPermissionGranted == true,
    );
    bloc.add(const DeviceSetupSmsPermissionRequested());

    final states = await statesFuture;
    await bloc.close();

    expect(states.last.smsPermissionGranted, isTrue);
    expect(states.last.smsPermissionPermanentlyDenied, isFalse);
  });

  test('denied sms request flags permanentlyDenied', () async {
    final bloc = DeviceSetupBloc(
      repository: _FakeDeviceSetupRepository(
        smsRequestResult: false,
        smsPermanentlyDenied: true,
      ),
    );

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.smsPermissionGranted != null,
    );
    bloc.add(const DeviceSetupSmsPermissionRequested());

    final states = await statesFuture;
    await bloc.close();

    expect(states.last.smsPermissionGranted, isFalse);
    expect(states.last.smsPermissionPermanentlyDenied, isTrue);
  });

  test('accepted battery request refreshes status', () async {
    final repo = _FakeDeviceSetupRepository(batteryRequestResult: true);
    final bloc = DeviceSetupBloc(repository: repo);

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.batteryUnrestricted != null,
    );
    bloc.add(const DeviceSetupBatteryOptimizationRequested());

    final states = await statesFuture;
    await bloc.close();

    expect(states.last.batteryUnrestricted, isTrue);
  });

  test('rejected battery request keeps previous status', () async {
    final bloc = DeviceSetupBloc(
      repository: _FakeDeviceSetupRepository(batteryRequestResult: false),
    );

    bloc.add(const DeviceSetupBatteryOptimizationRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await bloc.close();

    expect(bloc.state.batteryUnrestricted, isNull);
  });

  test('autostart open delegates to repository and marks screen opened',
      () async {
    final repo = _FakeDeviceSetupRepository();
    final bloc = DeviceSetupBloc(repository: repo);

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.autostartScreenOpened,
    );
    bloc.add(const DeviceSetupAutostartSettingsOpened());

    final states = await statesFuture;
    await bloc.close();

    expect(repo.autostartOpenCallCount, 1);
    expect(states.last.autostartScreenOpened, isTrue);
  });

  test('autostart acknowledge persists and updates state', () async {
    final repo = _FakeDeviceSetupRepository();
    final bloc = DeviceSetupBloc(repository: repo);

    final statesFuture = _collectUntil(
      bloc,
      (state) => state.autostartAcknowledged,
    );
    bloc.add(const DeviceSetupAutostartAcknowledged());

    final states = await statesFuture;
    await bloc.close();

    expect(repo.autostartAckCallCount, 1);
    expect(states.last.autostartAcknowledged, isTrue);
  });
}
