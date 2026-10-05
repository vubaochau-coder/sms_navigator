abstract class DeviceStorageService {
  Future<String?> getDeviceId();
  Future<void> saveDeviceId(String deviceId);
  Future<String?> getDeviceName();
  Future<void> saveDeviceName(String deviceName);
  Future<String?> getDeviceToken();
  Future<void> saveDeviceToken(String deviceToken);
  Future<void> clearDeviceToken();
  Future<String?> getServerUrl();
  Future<void> saveServerUrl(String serverUrl);
  Future<String?> getFcmToken();
  Future<void> saveFcmToken(String fcmToken);
  Future<void> clearAll();
}
