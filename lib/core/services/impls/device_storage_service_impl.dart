import '../../storage/local_storage_service.dart';
import '../../storage/secure_storage_service.dart';
import '../../storage/storage_keys.dart';
import '../device_storage_service.dart';

class DeviceStorageServiceImpl implements DeviceStorageService {
  DeviceStorageServiceImpl(this.localStorage, {SecureStorageService? secureStorage})
    : _secure = secureStorage ?? SecureStorageServiceImpl();

  final LocalStorageService localStorage;
  final SecureStorageService _secure;

  @override
  Future<String?> getDeviceId() async =>
      localStorage.getString(StorageKeys.deviceId);

  @override
  Future<void> saveDeviceId(String deviceId) =>
      localStorage.setString(StorageKeys.deviceId, deviceId);

  @override
  Future<String?> getDeviceName() async =>
      localStorage.getString(StorageKeys.deviceName);

  @override
  Future<void> saveDeviceName(String deviceName) =>
      localStorage.setString(StorageKeys.deviceName, deviceName);

  @override
  Future<String?> getDeviceToken() async {
    final secureToken = await _secure.read(StorageKeys.deviceToken);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    final legacy = localStorage.getString(StorageKeys.deviceToken);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(StorageKeys.deviceToken, legacy);
      await localStorage.remove(StorageKeys.deviceToken);
      return legacy;
    }
    return null;
  }

  @override
  Future<void> saveDeviceToken(String deviceToken) async {
    await _secure.write(StorageKeys.deviceToken, deviceToken);
    await localStorage.remove(StorageKeys.deviceToken);
  }

  @override
  Future<void> clearDeviceToken() async {
    await _secure.delete(StorageKeys.deviceToken);
    await localStorage.remove(StorageKeys.deviceToken);
  }

  @override
  Future<String?> getServerUrl() async =>
      localStorage.getString(StorageKeys.serverUrl);

  @override
  Future<void> saveServerUrl(String serverUrl) =>
      localStorage.setString(StorageKeys.serverUrl, serverUrl);

  @override
  Future<String?> getFcmToken() async =>
      localStorage.getString(StorageKeys.fcmToken);

  @override
  Future<void> saveFcmToken(String fcmToken) =>
      localStorage.setString(StorageKeys.fcmToken, fcmToken);

  @override
  Future<void> clearAll() async {
    await localStorage.remove(StorageKeys.deviceId);
    await localStorage.remove(StorageKeys.deviceName);
    await localStorage.remove(StorageKeys.deviceToken);
    await localStorage.remove(StorageKeys.serverUrl);
    await localStorage.remove(StorageKeys.fcmToken);
    await _secure.delete(StorageKeys.deviceToken);
  }
}
