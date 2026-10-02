import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
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
  DeviceStorageServiceImpl(this.localStorage, {SecureStorageService? secureStorage})
    : _secure = secureStorage ?? SecureStorageServiceImpl();

  final LocalStorageService localStorage;

  /// Device token là credential gọi API — lưu secure storage (GĐ4.1).
  final SecureStorageService _secure;

  @override
  Future<String?> getDeviceId() async =>
      localStorage.getString(StorageKeys.deviceId);

  @override
  Future<void> saveDeviceId(String deviceId) =>
      localStorage.setString(StorageKeys.deviceId, deviceId);

  @override
  Future<String?> getDeviceToken() async {
    final secureToken = await _secure.read(StorageKeys.deviceToken);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    // Migrate một lần từ shared_preferences (phiên bản trước GĐ4.1)
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
    await _secure.delete(StorageKeys.deviceToken);
  }
}
