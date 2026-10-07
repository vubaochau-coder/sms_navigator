import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
import 'package:sms_navigator/features/device/bloc/device_profile_cubit.dart';
import 'package:sms_navigator/features/device/bloc/device_profile_state.dart';

class _FakeNativeRelayService implements NativeRelayService {
  _FakeNativeRelayService({this.deviceName});

  final String? deviceName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getDeviceName() async => deviceName;
}

class _FakeDeviceStorageService implements DeviceStorageService {
  String? deviceId;
  String? deviceName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getDeviceId() async => deviceId;

  @override
  Future<String?> getDeviceName() async => deviceName;

  @override
  Future<void> saveDeviceName(String name) async {
    deviceName = name;
  }

  bool clearAllCalled = false;
  bool shouldThrowOnClearAll = false;

  @override
  Future<void> clearAll() async {
    if (shouldThrowOnClearAll) {
      throw Exception('Storage clear error');
    }
    clearAllCalled = true;
    deviceId = null;
    deviceName = null;
  }
}

class _FakeChannelRepository implements ChannelRepository {
  String? lastRenamedDevice;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> renameDevice(String name) async {
    lastRenamedDevice = name;
  }
}

void main() {
  late _FakeDeviceStorageService storage;
  late _FakeChannelRepository repository;
  late DeviceProfileCubit cubit;

  setUp(() {
    storage = _FakeDeviceStorageService();
    repository = _FakeChannelRepository();
    cubit = DeviceProfileCubit(
      deviceStorage: storage,
      channelRepository: repository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('DeviceProfileCubit', () {
    test('initial state has default deviceName and empty deviceId', () {
      expect(cubit.state, const DeviceProfileState());
    });

    test('loadDeviceProfile loads deviceId and deviceName from storage', () async {
      storage.deviceId = 'dev_123456';
      storage.deviceName = 'Pixel 8 Pro';

      await cubit.loadDeviceProfile();

      expect(cubit.state.deviceId, 'dev_123456');
      expect(cubit.state.deviceName, 'Pixel 8 Pro');
      expect(cubit.state.isLoading, isFalse);
    });

    test('loadDeviceProfile falls back to default name when null or empty and no native name', () async {
      storage.deviceId = 'dev_123';
      storage.deviceName = null;

      await cubit.loadDeviceProfile();

      expect(cubit.state.deviceName, 'Thiết bị của tôi');
    });

    test('loadDeviceProfile queries NativeRelayService when storage name is empty or default', () async {
      final fakeNative = _FakeNativeRelayService(deviceName: 'Samsung Galaxy A23');
      final cubitWithNative = DeviceProfileCubit(
        deviceStorage: storage,
        channelRepository: repository,
        nativeRelayService: fakeNative,
      );

      storage.deviceId = 'dev_123';
      storage.deviceName = 'Thiết bị của tôi';

      await cubitWithNative.loadDeviceProfile();

      expect(cubitWithNative.state.deviceName, 'Samsung Galaxy A23');
      expect(storage.deviceName, 'Samsung Galaxy A23');
      await cubitWithNative.close();
    });

    test('renameDevice updates repository and storage and emits updated name', () async {
      final success = await cubit.renameDevice('Samsung S24');

      expect(success, isTrue);
      expect(repository.lastRenamedDevice, 'Samsung S24');
      expect(storage.deviceName, 'Samsung S24');
      expect(cubit.state.deviceName, 'Samsung S24');
      expect(cubit.state.isRenaming, isFalse);
    });

    test('renameDevice ignores empty name', () async {
      final success = await cubit.renameDevice('   ');

      expect(success, isFalse);
      expect(repository.lastRenamedDevice, isNull);
    });

    test('clearDeviceData clears storage, resets state and returns true', () async {
      storage.deviceId = 'dev_123';
      storage.deviceName = 'Test Device';
      await cubit.loadDeviceProfile();

      final result = await cubit.clearDeviceData();

      expect(result, isTrue);
      expect(storage.clearAllCalled, isTrue);
      expect(cubit.state.deviceId, isEmpty);
      expect(cubit.state.deviceName, isEmpty);
    });

    test('clearDeviceData returns false on error', () async {
      storage.shouldThrowOnClearAll = true;

      final result = await cubit.clearDeviceData();

      expect(result, isFalse);
      expect(storage.clearAllCalled, isFalse);
    });
  });
}
