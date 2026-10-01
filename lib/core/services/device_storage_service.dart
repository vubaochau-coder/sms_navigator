import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';

/// Lưu trữ định danh & thông tin kết nối của thiết bị trên thiết bị.
/// Proxy chuyên biệt phía trên [LocalStorageService].
abstract class DeviceStorageService {
  Future<String?> getDeviceId();
  Future<void> saveDeviceId(String deviceId);
  Future<String?> getDeviceToken();
  Future<void> saveDeviceToken(String deviceToken);
  Future<String?> getServerUrl();
  Future<void> saveServerUrl(String serverUrl);
  Future<String?> getFcmToken();
  Future<void> saveFcmToken(String fcmToken);
  Future<void> clearAll();
}

class DeviceStorageServiceImpl implements DeviceStorageService {
  DeviceStorageServiceImpl(this.localStorage);

  final LocalStorageService localStorage;

  @override
  Future<String?> getDeviceId() async =>
      localStorage.getString(StorageKeys.deviceId);

  @override
  Future<void> saveDeviceId(String deviceId) =>
      localStorage.setString(StorageKeys.deviceId, deviceId);

  @override
  Future<String?> getDeviceToken() async =>
      localStorage.getString(StorageKeys.deviceToken);

  @override
  Future<void> saveDeviceToken(String deviceToken) =>
      localStorage.setString(StorageKeys.deviceToken, deviceToken);

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
    await localStorage.remove(StorageKeys.deviceToken);
    await localStorage.remove(StorageKeys.serverUrl);
    await localStorage.remove(StorageKeys.fcmToken);
  }
}
