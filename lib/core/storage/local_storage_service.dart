import 'package:shared_preferences/shared_preferences.dart';

/// Service trung tâm duy nhất quản lý Local Storage (SharedPreferences).
///
/// Toàn bộ ứng dụng KHÔNG được gọi trực tiếp `SharedPreferences.getInstance()`
/// mà phải đi qua service này (trừ AppBootstrap dùng factory [create]).
/// Các key bắt buộc lấy từ [StorageKeys] để tránh hardcode rải rác.
abstract class LocalStorageService {
  /// Factory duy nhất khởi tạo service từ SharedPreferences instance.
  /// Đây là nơi duy nhất được phép gọi `SharedPreferences.getInstance()`.
  static Future<LocalStorageService> create() async =>
      LocalStorageServiceImpl(await SharedPreferences.getInstance());

  String? getString(String key);

  Future<void> setString(String key, String value);

  bool? getBool(String key);

  Future<void> setBool(String key, bool value);

  Future<void> remove(String key);
}

class LocalStorageServiceImpl implements LocalStorageService {
  LocalStorageServiceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
