import 'package:shared_preferences/shared_preferences.dart';

/// Lưu trữ định danh & thông tin kết nối của thiết bị trên thiết bị.
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
  static const String _keyDeviceId = 'device_id';
  static const String _keyDeviceToken = 'device_token';
  static const String _keyServerUrl = 'server_url';
  static const String _keyFcmToken = 'fcm_token';

  @override
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeviceId);
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceId, deviceId);
  }

  @override
  Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeviceToken);
  }

  @override
  Future<void> saveDeviceToken(String deviceToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceToken, deviceToken);
  }

  @override
  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  @override
  Future<void> saveServerUrl(String serverUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, serverUrl);
  }

  @override
  Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  @override
  Future<void> saveFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, fcmToken);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyDeviceToken);
    await prefs.remove(_keyServerUrl);
    await prefs.remove(_keyFcmToken);
  }
}
